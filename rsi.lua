local client = client
local keygrabber = keygrabber
local mousegrabber = mousegrabber
local timer = timer
local os = os
local ipairs = ipairs
local table = table
local naughty = require('naughty')

module("rsi")

local password = {'q', 'u', 'i', 't'}
local work_time = 55
local rest_time = 5
local postpone_time = 5

local last_rest
local last_work

local strokes
local check_timer
local working = true

local banner

local function check()
    if working and os.time() - last_rest > work_time*60 then
        start_rest()
    end

    if not working and os.time - last_work > rest_time*60 then
        stop_rest()
    end
end

local function mouse_handler()
    return true
end

local function key_handler(mod, key, event)
    if event == "release" then return true end

    if key == 'Return' and #strokes == #password then
        for i, k in ipairs(strokes) do
            if k ~= password[i] then
                return true
            end
        end
        stop_rest(true)
    end

    table.insert(strokes, key)
    if #strokes > #password then
        table.remove(strokes, 1)
    end

    return true
end

function start_rest()
    working = false
    last_work = os.time()
    strokes = {}

    mousegrabber.run(mouse_handler, 'watch')
    keygrabber.run(key_handler)

    if banner then
        naughty.destroy(banner)
        banner = nil
    end

    banner = naughty.notify({
        text = 'Take break',
        timeout = rest_time*60,
        width = 100,
    })

end

function stop_rest(postpone)
    if banner then
        naughty.destroy(banner)
        banner = nil
    end

    working = true

    last_rest = os.time()
    if postpone then
        last_rest = last_rest - work_time*60 + postpone_time*60
    end

    keygrabber.stop()
    mousegrabber.stop()
end

function run(args)
    if not args then args = {} end

    work_time = args.work or 55
    rest_time = args.rest or 5

    last_rest = os.time()

    check_timer = timer{timeout = 10}
    check_timer:add_signal('timeout', check)
    check_timer:start()
end