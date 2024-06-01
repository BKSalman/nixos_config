use std::cell::RefCell;
use std::time::Duration;

use chrono::format::StrftimeItems;
use chrono::Local;
use jay_config::input::{get_default_seat, Seat};
use jay_config::keyboard::mods::{Modifiers, ALT, CTRL, MOD4, SHIFT};
use jay_config::keyboard::parse_keymap;
use jay_config::keyboard::syms::{
    KeySym, SYM_Arabic_alef, SYM_Arabic_alefmaksura, SYM_Arabic_beh, SYM_Arabic_dad,
    SYM_Arabic_gaf, SYM_Arabic_hamza, SYM_Arabic_hamzaonwaw, SYM_Arabic_meem, SYM_Arabic_noon,
    SYM_Arabic_ra, SYM_Arabic_tah, SYM_Arabic_yeh, SYM_Print, SYM_Super_L, SYM_b, SYM_c, SYM_d,
    SYM_f, SYM_g, SYM_h, SYM_j, SYM_k, SYM_l, SYM_n, SYM_p, SYM_q, SYM_r, SYM_t, SYM_v, SYM_x,
    SYM_0, SYM_1, SYM_2, SYM_3, SYM_4, SYM_5, SYM_6, SYM_7, SYM_8, SYM_9, SYM_F1, SYM_F10, SYM_F11,
    SYM_F12, SYM_F2, SYM_F3, SYM_F4, SYM_F5, SYM_F6, SYM_F7, SYM_F8, SYM_F9,
};
use jay_config::status::set_status;
use jay_config::timer::{duration_until_wall_clock_is_multiple_of, get_timer};
use jay_config::video::{on_graphics_initialized, set_gfx_api, GfxApi};
use jay_config::{config, exec, get_workspace, quit, reload, switch_to_vt, Axis, Direction};
use sysinfo::{CpuRefreshKind, MemoryRefreshKind, RefreshKind, System};

const MOD: Modifiers = MOD4;
const SUPER: KeySym = SYM_Super_L;

fn setup_status() {
    let time_format: Vec<_> = StrftimeItems::new("%Y-%m-%d %H:%M:%S").collect();
    let specifics = RefreshKind::new()
        .with_cpu(CpuRefreshKind::new().with_cpu_usage())
        .with_memory(MemoryRefreshKind::new().with_ram());
    let system = RefCell::new(System::new_with_specifics(specifics));
    let update_status = move || {
        let mut system = system.borrow_mut();
        system.refresh_specifics(specifics);
        let cpu_usage = system.cpus().iter().map(|cpu| cpu.cpu_usage()).sum::<f32>() / 100.0;
        let used = system.used_memory() as f64 / (1024 * 1024) as f64;
        let total = system.total_memory() as f64 / (1024 * 1024) as f64;
        let status = format!(
            r##"MEM: {used:.1}/{total:.1} <span color="#333333">|</span> CPU: {cpu_usage:5.2} <span color="#333333">|</span> {time}"##,
            time = Local::now().format_with_items(time_format.iter())
        );
        set_status(&status);
    };
    update_status();
    let period = Duration::from_secs(5);
    let timer = get_timer("status_timer");
    timer.repeated(duration_until_wall_clock_is_multiple_of(period), period);
    timer.on_tick(update_status);
}

fn setup_keybinds(seat: Seat) {
    seat.bind(MOD | SYM_h, move || seat.focus(Direction::Left));
    seat.bind(MOD | SYM_Arabic_alef, move || seat.focus(Direction::Left));

    seat.bind(MOD | SYM_j, move || seat.focus(Direction::Down));
    seat.bind(MOD | SYM_Arabic_tah, move || seat.focus(Direction::Down));

    seat.bind(MOD | SYM_k, move || seat.focus(Direction::Up));
    seat.bind(MOD | SYM_Arabic_noon, move || seat.focus(Direction::Up));

    seat.bind(MOD | SYM_l, move || seat.focus(Direction::Right));
    seat.bind(MOD | SYM_Arabic_meem, move || seat.focus(Direction::Right));

    seat.bind(MOD | SHIFT | SYM_h, move || seat.move_(Direction::Left));
    seat.bind(MOD | SHIFT | SYM_Arabic_alef, move || {
        seat.move_(Direction::Left)
    });

    seat.bind(MOD | SHIFT | SYM_j, move || seat.move_(Direction::Down));
    seat.bind(MOD | SHIFT | SYM_Arabic_tah, move || {
        seat.move_(Direction::Down)
    });

    seat.bind(MOD | SHIFT | SYM_k, move || seat.move_(Direction::Up));
    seat.bind(MOD | SHIFT | SYM_Arabic_noon, move || {
        seat.move_(Direction::Up)
    });

    seat.bind(MOD | SYM_g, move || seat.create_split(Axis::Horizontal));
    seat.bind(MOD | SYM_b, move || seat.create_split(Axis::Vertical));
    seat.bind(MOD | SYM_t, move || seat.toggle_split());
    seat.bind(MOD | SYM_p, move || seat.focus_parent());

    seat.bind(MOD | SHIFT | SYM_Arabic_meem, move || {
        seat.move_(Direction::Right)
    });

    seat.bind(MOD | SYM_q, || exec::Command::new("kitty").spawn());
    seat.bind(MOD | SYM_Arabic_dad, || exec::Command::new("kitty").spawn());

    seat.bind(MOD | SYM_d, || exec::Command::new("bemenu-run").spawn());
    seat.bind(MOD | SYM_Arabic_yeh, || {
        exec::Command::new("bemenu-run").spawn()
    });

    seat.set_window_management_key(SUPER);

    // seat.bind(MOD | SYM_d, || {
    //     exec::Command::new("sh")
    //         .arg("-c")
    //         .arg("pkill rofi || ~/.config/rofi/launcher.sh")
    //         .spawn()
    // });

    seat.bind(MOD | SYM_n, move || seat.disable_pointer_constraint());
    seat.bind(MOD | SYM_Arabic_alefmaksura, move || {
        seat.disable_pointer_constraint()
    });

    let fnkeys = [
        SYM_F1, SYM_F2, SYM_F3, SYM_F4, SYM_F5, SYM_F6, SYM_F7, SYM_F8, SYM_F9, SYM_F10, SYM_F11,
        SYM_F12,
    ];
    for (i, sym) in fnkeys.into_iter().enumerate() {
        seat.bind(CTRL | ALT | sym, move || switch_to_vt(i as u32 + 1));
    }

    let numkeys = [
        SYM_1, SYM_2, SYM_3, SYM_4, SYM_5, SYM_6, SYM_7, SYM_8, SYM_9, SYM_0,
    ];
    for (i, sym) in numkeys.into_iter().enumerate() {
        let ws = get_workspace(&format!("{}", i + 1));
        seat.bind(MOD | sym, move || seat.show_workspace(ws));
        seat.bind(MOD | SHIFT | sym, move || seat.set_workspace(ws));
    }

    seat.bind(MOD | SYM_f, move || seat.toggle_fullscreen());
    seat.bind(MOD | SYM_Arabic_beh, move || seat.toggle_fullscreen());

    seat.bind(MOD | SYM_v, move || seat.toggle_floating());
    seat.bind(MOD | SYM_Arabic_ra, move || seat.toggle_floating());

    seat.bind(MOD | SYM_c, move || seat.close());
    seat.bind(MOD | SYM_Arabic_hamzaonwaw, move || seat.close());

    seat.bind(MOD | SHIFT | SYM_x, || quit());
    seat.bind(MOD | SHIFT | SYM_Arabic_hamza, || quit());

    seat.bind(MOD | SHIFT | SYM_r, || reload());
    seat.bind(MOD | SHIFT | SYM_Arabic_gaf, || reload());

    seat.bind(SYM_Print, || {
        exec::Command::new("sh").arg("-c").arg(
            r#"jay run-privileged -- grim -g "$(slurp)" - | tee $(xdg-user-dir PICTURES)/$(date +"screenshot_%Y-%m-%d_%H:%M:%S.png") | wl-copy --type image/png"#
        ).spawn()
    });
}

fn configure() {
    set_gfx_api(GfxApi::Vulkan);

    setup_status();

    let seat = get_default_seat();

    seat.set_keymap(parse_keymap(include_str!("keymap.xkb")));

    setup_keybinds(seat);

    on_graphics_initialized(|| {
        exec::Command::new("jay")
            .arg("run-privileged")
            .arg("--")
            .arg("wl-paste")
            .arg("-t")
            .arg("text")
            .arg("--watch")
            .arg("cliphist")
            .arg("store")
            .spawn();

        exec::Command::new("swww-daemon").spawn();
    });
}

config!(configure);
