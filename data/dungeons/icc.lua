local _, ns = ...
ns.dungeons = ns.dungeons or {}
ns.dungeons.icc = {
    maps = {
        [1] = { floor = 1, calib = { ax = 0.961559, bx = 0.006594, ay = 0.866950, by = -0.004694 } },
        [2] = { floor = 6 },
    },
    loc = {
        trash_entrance = { kind = "corridor", map = 1, crop = { 0.3176, 0.4466, 0.0408, 0.257 } },
        trash_gate     = { kind = "corridor", map = 1, crop = { 0.3163, 0.4456, 0.2593, 0.45 } },
        marrowgar      = { kind = "boss",     map = 1, crop = { 0.3085, 0.4534, 0.4501, 0.6381 } },
        lanathel       = { kind = "boss",     map = 2, crop = { 0.387, 0.6082, 0.2165, 0.5913 },
                           calib = { ax = 0.939218, bx = 0.020182, ay = 0.880444, by = -0.007590 } },
    },
}
