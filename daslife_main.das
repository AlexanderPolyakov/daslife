require daslib/media
// options debugger            // uncomment for debug in VS Code
// require daslib/debug        // uncomment for debug in VS Code

enum GameState
    Painting
    Running


let
    bg_color = 0x000000
    grid_color = 0xaaaaaa
    cur_pix_color = 0x80aaaa00
    fill_pix_color = 0x800000
    fix_size = 10

var
    state = GameState Painting
    init_buf_size: int2
    paint_offs: int2
    paint_coords: int2
    init_buffer: array<bool>
    game_buffer: array<bool>
    game_image: Image
    seed: int4

def painting()
    paint_coords = (int2(get_mouse_position()) - paint_offs) / fix_size
    if get_mouse_button_down(MB_LEFT) && paint_coords.x >= 0 && paint_coords.x < init_buf_size.x && paint_coords.y >=0 && paint_coords.y < init_buf_size.y
        let idx = paint_coords.y * init_buf_size.x + paint_coords.x
        init_buffer[idx] = !init_buffer[idx]


def painting_draw()
    let sz = init_buf_size * fix_size
    for y in range(init_buf_size.y + 1)
        let yPos = paint_offs.y + y * fix_size
        line(paint_offs.x, yPos, paint_offs.x + sz.x, yPos, grid_color)
    for x in range(init_buf_size.x + 1)
        let xPos = paint_offs.x + x * fix_size
        line(xPos, paint_offs.y, xPos, paint_offs.y + sz.y, grid_color)
    for idx in range(length(init_buffer))
        if init_buffer[idx]
            let pixelCoords = paint_offs + int2(idx % init_buf_size.x, idx / init_buf_size.y) * fix_size + int2(1)
            fill_rect(pixelCoords.x, pixelCoords.y, fix_size-1, fix_size-1, fill_pix_color)
    if paint_coords.x >= 0 && paint_coords.x < init_buf_size.x && paint_coords.y >=0 && paint_coords.y < init_buf_size.y
        let pixelCoords = paint_offs + paint_coords * fix_size + int2(1)
        fill_rect(pixelCoords.x, pixelCoords.y, fix_size-1, fix_size-1, cur_pix_color)

def init_game_image()
    let imgSz = int2(game_image.width, game_image.height)
    resize(game_buffer, game_image.width * game_image.height)
    for idx in range(length(game_buffer))
        game_buffer[idx] = false
    let offs = (imgSz - init_buf_size) / 2
    for idx in range(length(init_buffer))
        let x = idx % init_buf_size.x + offs.x
        let y = idx / init_buf_size.x + offs.y
        game_buffer[y * imgSz.x + x] = init_buffer[idx]

def game_of_life()
    let imgSz = int2(game_image.width, game_image.height)
    // game of life rules
    let prevBuffer := game_buffer
    for y in range(imgSz.y)
        for x in range(imgSz.x)
            let idx = y * imgSz.x + x
            var n = prevBuffer[idx] ? -1 : 0
            for y1 in range(y-1, y+2)
                for x1 in range(x-1, x+2)
                    n += prevBuffer[((y1 + imgSz.y) % imgSz.y) * imgSz.x + (x1 + imgSz.x) % imgSz.x] ? 1 : 0
            game_buffer[idx] = n == 3 || (n == 2 && prevBuffer[idx])
    // copy to image
    for idx in range(length(game_buffer))
        let x = idx % imgSz.x
        let y = idx / imgSz.x
        set_pixel(game_image, x, y, game_buffer[idx] ? fill_pix_color : 0x000000)

def game_of_life_draw()
    let w = get_screen_width()
    let h = get_screen_height()
    draw_image(game_image, (w - game_image.width) / 2, (h - game_image.height) / 2)

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize
    set_window_title("life")
    let w = get_screen_width()
    let h = get_screen_height()
    let sz = min(w,h)
    init_buf_size = int2(sz / 20, sz / 20)

    let scrSz = int2(get_screen_width(), get_screen_height())
    let paintSz = init_buf_size * fix_size
    paint_offs = (scrSz - paintSz) / 2

    resize(init_buffer, init_buf_size.x * init_buf_size.y)

    game_image <- create_image(init_buf_size.x * 10, init_buf_size.y * 10)

    randomize_seed(seed)
    return

var
    fps = 0f

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()
    if get_key_press(VK_SPACE)
        state = state == GameState Painting ? GameState Running : GameState Painting
        if state == GameState Running // just switched to running state, need to init image
            init_game_image()
    if get_key_press(VK_C)
        for idx in range(length(init_buffer))
            init_buffer[idx] = false
    if get_key_press(VK_R)
        for idx in range(length(init_buffer))
            init_buffer[idx] = random_float(seed) > 0.5

    if state == GameState Painting
        painting()
    else
        game_of_life()
    fps = 1f / dt
    return

// this function will be called every frame after 'act',
// you can draw anything in this function
[export]
def draw
    let w = float(get_screen_width())
    let h = float(get_screen_height())
    if state == GameState Painting
        painting_draw()
    else
        game_of_life_draw()
    text_out(20, 20, "game state is {state}", 0xffffff)
    text_out(20, 40, "fps is {int(fps)} for img {game_image.width}x{game_image.height}", 0xffffff)
    text_out(20, 60, "Press space to toggle cell state, click to paint, c to clear, r for random", 0xffffff)
    return
