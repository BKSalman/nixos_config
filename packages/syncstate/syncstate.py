#
# Copyright (C) by Klaas Freitag <freitag@owncloud.com>
#
# This program is the core of OwnCloud integration to Nemo
# It will be installed on /usr/share/nemo-python/extensions/ with the paquet owncloud-client-nemo
# (https://github.com/owncloud/client/edit/master/shell_integration/nemo/syncstate.py)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.

import os
import urllib
import socket

from gi.repository import GObject, Nemo

# Please do not touch the following line.
# The reason is that we use a script to adopt this file for branding
# by replacing this line with the branding app name. If the following
# line is changed, the script can not match the pattern and fails.
appname = 'Nextcloud'

print("Initializing "+appname+"-client-nemo extension")


def get_local_path(url):
    if url[0:7] == 'file://':
        url = url[7:]
    return urllib.unquote(url)

def get_runtime_dir():
    """Returns the value of $XDG_RUNTIME_DIR, a directory path.

    If the value is not set, returns the same default as in Qt5
    """
    try:
        return os.environ['XDG_RUNTIME_DIR']
    except KeyError:
        fallback = '/tmp/runtime-' + os.environ['USER']
        return fallback


class SocketConnect(GObject.GObject):
    def __init__(self):
        GObject.GObject.__init__(self)
        self.connected = False
        self.registered_paths = {}
        self._watch_id = 0
        self._sock = None
        self._listeners = [self._update_registered_paths]
        self._remainder = ''
        self.nemoVFSFile_table = {}  # not needed in this object actually but shared 
                                         # all over the other objects.

        # returns true when one should try again!
        if self._connectToSocketServer():
            GObject.timeout_add(5000, self._connectToSocketServer)

    def reconnect(self):
        self._sock.close()
        self.connected = False
        GObject.source_remove(self._watch_id)
        GObject.timeout_add(5000, self._connectToSocketServer)

    def sendCommand(self, cmd):
        # print("Server command: " + cmd)
        if self.connected:
            try:
                self._sock.send(cmd)
            except:
                print("Sending failed.")
                self.reconnect()
        else:
            print("Cannot send, not connected!")

    def addListener(self, listener):
        self._listeners.append(listener)

    def _connectToSocketServer(self):
        try:
            self._sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            postfix = "/" + appname + "/socket"  # Should use os.path.join instead
            sock_file = get_runtime_dir() + postfix
            print ("Socket: " + sock_file + " <=> " + postfix)
            if sock_file != postfix:
                try:
                    print("Socket File: " + sock_file)
                    self._sock.connect(sock_file)
                    self.connected = True
                    print("Setting connected to %r." % self.connected )
                    self._watch_id = GObject.io_add_watch(self._sock, GObject.IO_IN, self._handle_notify)
                    print("Socket watch id: " + str(self._watch_id))
                    return False  # Don't run again
                except Exception as e:
                    print("Could not connect to unix socket. " + str(e))
            else:
                print("Sock-File not valid: " + sock_file)
        except Exception as e:  # Bad habbit
            print("Connect could not be established, try again later.")
            self._sock.close()

        return True  # Run again, if enabled via timeout_add()

    # Notify is the raw answer from the socket
    def _handle_notify(self, source, condition):
        data = source.recv(1024)
        # Prepend the remaining data from last call
        if len(self._remainder) > 0:
            data = self._remainder + data
            self._remainder = ''

        if len(data) > 0:
            # Remember the remainder for next round
            lastNL = data.rfind('\n');
            if lastNL > -1 and lastNL < len(data):
                self._remainder = data[lastNL+1:]
                data = data[:lastNL]

            for l in data.split('\n'):
                self._handle_server_response(l)
        else:
            return False

        return True  # Run again

    def _handle_server_response(self, line):
        print("Server response: " + line)
        parts = line.split(':')
        action = parts[0]
        args = parts[1:]

        for listener in self._listeners:
            listener(action, args)

    def _update_registered_paths(self, action, args):
        if action == 'REGISTER_PATH':
            self.registered_paths[args[0]] = 1
        elif action == 'UNREGISTER_PATH':
            del self.registered_paths[args[0]]

            # Check if there are no paths left. If so, its usual
            # that mirall went away. Try reconnecting.
            if not self.registered_paths:
                self.reconnect()

socketConnect = SocketConnect()


class MenuExtension(GObject.GObject, Nemo.MenuProvider):
    def __init__(self):
        GObject.GObject.__init__(self)

    def get_file_items(self, window, files):
        if len(files) != 1:
            return
        file = files[0]
        items = []

        # Internal or external file?!
        syncedFile = False
        for reg_path in socketConnect.registered_paths:
            topLevelFolder = False
            filename = get_local_path(file.get_uri())
            # Check if its a folder (ends with an /), if yes add a "/"
            # otherwise it will not find the entry in the table
            if os.path.isdir(filename + "/"):
                filename += "/"
                # Check if toplevel folder, we need to ignore those as they cannot be shared
                if filename == reg_path:
                    topLevelFolder=True                
            # Only show the menu extension if the file is synced and the sync
            # status is ok. Not for ignored files etc.
            # ignore top level folders
            if filename.startswith(reg_path) and topLevelFolder == False and socketConnect.nemoVFSFile_table[filename]['state'].startswith('OK'):
                syncedFile = True

        # If it is neither in a synced folder or is a directory
        if not syncedFile:
            return items

        # Create a menu item
        labelStr = "Share with " + appname + "..."
        item = Nemo.MenuItem(name='NemoPython::ShareItem', label=labelStr,
                tip='Share file {} through {}'.format(file.get_name(), appname) )
        item.connect("activate", self.menu_share, file)
        items.append(item)

        return items


    def menu_share(self, menu, file):
        filename = get_local_path(file.get_uri())
        print("Share file " + filename)
        socketConnect.sendCommand("SHARE:" + filename + "\n")


class SyncStateExtension(GObject.GObject, Nemo.ColumnProvider, Nemo.InfoProvider):
    def __init__(self):
        GObject.GObject.__init__(self)

        socketConnect.nemoVFSFile_table = {}
        socketConnect.addListener(self.handle_commands)

    def find_item_for_file(self, path):
        if path in socketConnect.nemoVFSFile_table:
            return socketConnect.nemoVFSFile_table[path]
        else:
            return None

    def askForOverlay(self, file):
        # print("Asking for overlay for "+file)  # For debug only
        if os.path.isdir(file):
            folderStatus = socketConnect.sendCommand("RETRIEVE_FOLDER_STATUS:"+file+"\n");

        if os.path.isfile(file):
            fileStatus = socketConnect.sendCommand("RETRIEVE_FILE_STATUS:"+file+"\n");

    def invalidate_items_underneath(self, path):
        update_items = []
        if not socketConnect.nemoVFSFile_table:
            self.askForOverlay(path)
        else:
            for p in socketConnect.nemoVFSFile_table:
                if p == path or p.startswith(path):
                    item = socketConnect.nemoVFSFile_table[p]['item']
                    update_items.append(p)

            for path1 in update_items:
                socketConnect.nemoVFSFile_table[path1]['item'].invalidate_extension_info()

    # Handles a single line of server response and sets the emblem
    def handle_commands(self, action, args):
        # file = args[0]  # For debug only
        # print("Action for " + file + ": " + args[0])  # For debug only
        if action == 'STATUS':
            newState = args[0]
            filename = ':'.join(args[1:])

            itemStore = self.find_item_for_file(filename)
            if itemStore:
                if( not itemStore['state'] or newState != itemStore['state'] ):
                    item = itemStore['item']

                    # print("Setting emblem on " + filename + "<>" + emblem + "<>")  # For debug only

                    # If an emblem is already set for this item, we need to
                    # clear the existing extension info before setting a new one.
                    #
                    # That will also trigger a new call to
                    # update_file_info for this item! That's why we set
                    # skipNextUpdate to True: we don't want to pull the
                    # current data from the client after getting a push
                    # notification.
                    invalidate = itemStore['state'] != None
                    if invalidate:
                        item.invalidate_extension_info()
                    self.set_emblem(item, newState)

                    socketConnect.nemoVFSFile_table[filename] = {
                        'item': item,
                        'state': newState,
                        'skipNextUpdate': invalidate }

        elif action == 'UPDATE_VIEW':
            # Search all items underneath this path and invalidate them
            if args[0] in socketConnect.registered_paths:
                self.invalidate_items_underneath(args[0])

        elif action == 'REGISTER_PATH':
            self.invalidate_items_underneath(args[0])
        elif action == 'UNREGISTER_PATH':
            self.invalidate_items_underneath(args[0])

    def set_emblem(self, item, state):
        Emblems = { 'OK'        : appname +'_ok',
                    'SYNC'      : appname +'_sync',
                    'NEW'       : appname +'_sync',
                    'IGNORE'    : appname +'_warn',
                    'ERROR'     : appname +'_error',
                    'OK+SWM'    : appname +'_ok_shared',
                    'SYNC+SWM'  : appname +'_sync_shared',
                    'NEW+SWM'   : appname +'_sync_shared',
                    'IGNORE+SWM': appname +'_warn_shared',
                    'ERROR+SWM' : appname +'_error_shared',
                    'NOP'       : ''
                  }

        emblem = 'NOP' # Show nothing if no emblem is defined.
        if state in Emblems:
            emblem = Emblems[state]
        item.add_emblem(emblem)

    def update_file_info(self, item):
        if item.get_uri_scheme() != 'file':
            return

        filename = get_local_path(item.get_uri())
        if item.is_directory():
            filename += '/'

        inScope = False
        for reg_path in socketConnect.registered_paths:
            if filename.startswith(reg_path):
                inScope = True
                break

        if not inScope:
            return

        # Ask for the current state from the client -- unless this update was
        # triggered by receiving a STATUS message from the client in the first
        # place.
        itemStore = self.find_item_for_file(filename)
        if itemStore and itemStore['skipNextUpdate'] and itemStore['state']:
            itemStore['skipNextUpdate'] = False
            itemStore['item'] = item
            self.set_emblem(item, itemStore['state'])
        else:
            socketConnect.nemoVFSFile_table[filename] = {
                'item': item,
                'state': None,
                'skipNextUpdate': False }

            # item.add_string_attribute('share_state', "share state")  # ?
            self.askForOverlay(filename)
