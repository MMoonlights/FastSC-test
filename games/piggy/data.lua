displayNames = {
    BlueKey = "Blue Key",
    OrangeKey = "Orange Key",
    GreenKey = "Green Key",
    RedKey = "Red Key",
    YellowKey = "Yellow Key",
    WhiteKey = "White Key",
    PurpleKey = "Purple Key",
    BlueKeycard = "Blue Keycard",
    RedKeycard = "Red Keycard",
    OrangeKeycard = "Orange Keycard",
    GreenKeycard = "Green Keycard",
    RedGear = "Red Gear",
    GreenGear = "Green Gear",
    WhiteGear = "White Gear",
    RedEgg = "Red Egg",
    GreenEgg = "Green Egg",
    BlueEgg = "Blue Egg",
    KeyCode = "Key Code",
    Coin = "Coin",
    Torch = "Torch",
    Mirror = "Mirror",
    PurpleVial = "Purple Vial",
    TankBullet = "Tank Bullet",
    Apple = "Apple",
    Rose = "Rose",
    WaterGun = "Water Gun",
    FireExtinguisher = "Fire Extinguisher",
    SmokeBomb = "Smoke Bomb",
    SmokeGrenade = "Smoke Grenade",
    GrapplingHook = "Grappling Hook",
    WoodenSword = "Wooden Sword",
    FencingFoil = "Fencing Foil",
    EmptyVial = "Empty Vial",
    GreenVial = "Green Vial",
    PinkVial = "Pink Vial",
    GreenWire = "Green Wire",
    RedWire = "Red Wire",
    BlueWire = "Blue Wire",
    YellowWire = "Yellow Wire",
    Screwdriver = "Screwdriver",
    Scissors = "Scissors",
    Blowtorch = "Blowtorch",
    Flashlight = "Flashlight",
    Crowbar = "Crowbar",
    Dynamite = "Dynamite",
    Battery = "Battery",
    Batteries = "Batteries",
    Remote = "Remote",
    RemoteControl = "Remote Control",
    Mop = "Mop",
    ElevatorKey = "Elevator Key",
    Presents = "Presents",
    Dreidel = "Dreidel",
    FencingSword = "Fencing Sword",
    Ladder = "Ladder",
    Shovel = "Shovel",
    Candle = "Candle",
    Hammer = "Hammer",
    Wrench = "Wrench",
    Plank = "Plank",
    Ammo = "Ammo",
    Gun = "Gun",
    Carrot = "Carrot",
    Grass = "Grass",
    Bone = "Bone",
    Book = "Book",
    Rope = "Rope",
    Ticket = "Ticket",
    TNT = "TNT",
    Pipe = "Pipe",
    Bat = "Bat",
    Gas = "Gas",
    Axe = "Axe",
    Gear = "Gear",
    Keycard = "Keycard",
    Key = "Key",
    Mallet = "Mallet",
    Crossbow = "Crossbow",
    RobotToy = "Robot Toy",
    DinosaurToy = "Dinosaur Toy",
    Barbell = "Barbell",
    Pie = "Pie",
    SprayCan = "Spray Can",
    BlackKey = "Black Key",
    Crystal = "Crystal",
    MilitaryKnife = "Military Knife",
    FrontDoorKey = "Front Door Key",
    DayPaintBucket = "Day Paint Bucket",
    NightPaintBucket = "Night Paint Bucket",
    SunsetPaintBucket = "Sunset Paint Bucket",
    Snowball = "Snowball",
    PremiumTicket = "Premium Ticket",
    Strawberry = "Strawberry",
    Box = "Box",
    Katana = "Katana",
    Prop = "Prop",
    Clothing = "Clothing",
    Clothes = "Clothes",
}

aliases = {}
function token(value)
    return string.lower(tostring(value or "")):gsub("[^%w]", "")
end

for id, display in pairs(displayNames) do
    aliases[token(id)] = id
    aliases[token(display)] = id
end

aliases[token("Remote")] = "RemoteControl"
aliases[token("TV Remote")] = "RemoteControl"
aliases[token("Remote Control")] = "RemoteControl"
aliases[token("Fencing Foil")] = "FencingSword"
aliases[token("Fencing Sword")] = "FencingSword"
aliases[token("Present")] = "Presents"
aliases[token("Presents")] = "Presents"
aliases[token("Elevator Key")] = "ElevatorKey"
aliases[token("Mop")] = "Mop"
aliases[token("Pink Vial")] = "PurpleVial"
aliases[token("Purple Vial")] = "PurpleVial"
aliases[token("Gasoline")] = "Gas"
aliases[token("Gas Can")] = "Gas"
aliases[token("Gas Canister")] = "Gas"
aliases[token("Tank Shell")] = "TankBullet"
aliases[token("Tank Bullet")] = "TankBullet"
aliases[token("Cannon Shell")] = "TankBullet"
aliases[token("Coin")] = "Coin"
aliases[token("Token")] = "Coin"
aliases[token("Dinosaur")] = "DinosaurToy"
aliases[token("Dinosaur Toy")] = "DinosaurToy"
aliases[token("Robot")] = "RobotToy"
aliases[token("Robot Toy")] = "RobotToy"
aliases[token("Dumbbell")] = "Barbell"
aliases[token("Barbell")] = "Barbell"
aliases[token("Spray")] = "SprayCan"
aliases[token("Spray Paint")] = "SprayCan"
aliases[token("Spray Can")] = "SprayCan"
aliases[token("Front Door Key")] = "FrontDoorKey"
aliases[token("Day Paint")] = "DayPaintBucket"
aliases[token("Day Paint Bucket")] = "DayPaintBucket"
aliases[token("Night Paint")] = "NightPaintBucket"
aliases[token("Night Paint Bucket")] = "NightPaintBucket"
aliases[token("Sunset Paint")] = "SunsetPaintBucket"
aliases[token("Sunset Paint Bucket")] = "SunsetPaintBucket"
aliases[token("Gift")] = "Presents"
aliases[token("Present")] = "Presents"
aliases[token("Premium Pass")] = "PremiumTicket"
aliases[token("Premium Ticket")] = "PremiumTicket"
aliases[token("Costume")] = "Clothing"
aliases[token("Clothes")] = "Clothing"
aliases[token("Clothing")] = "Clothing"
aliases[token("Theater Prop")] = "Prop"
aliases[token("Theatre Prop")] = "Prop"
aliases[token("Props")] = "Prop"
aliases[token("Torch")] = "Torch"
aliases[token("Mirror")] = "Mirror"
aliases[token("Red Egg")] = "RedEgg"
aliases[token("Green Egg")] = "GreenEgg"
aliases[token("Blue Egg")] = "BlueEgg"

mapProfiles = {
    House = {
        Gates = {
            WhiteKey = {Synthetic = {"RedGear", "GreenGear"}},
            KeyCode = {Active = {"YellowKey"}},
        },
        Depends = {
            KeyCode = {"YellowKey"},
            WhiteKey = {"RedGear", "GreenGear"},
        },
        Synthetic = {
            WhiteKey = {"RedGear", "GreenGear"},
        },
        PreObjectives = {"RedGear", "GreenGear"},
        Priority = {
            GreenKey = 10, RedKey = 20, BlueKey = 30, Plank = 34, YellowKey = 35, OrangeKey = 40,
            Wrench = 42, RedGear = 45, GreenGear = 46, Hammer = 55, KeyCode = 57, WhiteKey = 100,
        },
    },
    Station = {
        Gates = {
            Gas = {Present = {"Battery"}, Active = {"Battery"}},
            WhiteKey = {Active = {"YellowKey"}},
        },
        Depends = {
            WhiteKey = {"YellowKey", "RedKey"},
            Gas = {"Battery"},
        },
        Counters = {
            Battery = 2,
        },
        Priority = {
            GreenKey = 10, RedKey = 15, BlueKey = 20, OrangeKey = 25, YellowKey = 30,
            Battery = 35, Plank = 40, Hammer = 45, Wrench = 46, WhiteKey = 60, Gas = 100,
        },
    },
    Gallery = {
        Gates = {
            WhiteKey = {Present = {"RedEgg", "GreenEgg"}, Active = {"RedEgg", "GreenEgg"}},
        },
        Depends = {
            WhiteKey = {"RedEgg", "GreenEgg"},
        },
        Priority = {
            RedKey = 10, BlueKey = 15, GreenKey = 20, OrangeKey = 25, YellowKey = 30,
            Plank = 35, Hammer = 40, Wrench = 41, RedEgg = 50, GreenEgg = 50, WhiteKey = 100,
        },
    },
    Forest = {
        Gates = {
            Wrench = {Active = {"YellowKey", "Plank"}},
            WhiteKey = {Present = {"Torch"}, Active = {"Torch"}},
        },
        Depends = {
            Wrench = {"YellowKey", "Plank"},
            WhiteKey = {"Torch"},
        },
        Priority = {
            GreenKey = 10, RedKey = 15, BlueKey = 20, OrangeKey = 25, YellowKey = 30,
            Plank = 35, Hammer = 40, Wrench = 45, Torch = 50, WhiteKey = 100,
        },
    },
    School = {
        Gates = {
            Hammer = {Active = {"RedKey"}},
            GreenGear = {Active = {"Book"}},
        },
        Depends = {
            Hammer = {"RedKey"},
            GreenGear = {"Book"},
        },
        Priority = {
            GreenKey = 10, BlueKey = 15, OrangeKey = 20, Book = 25,
            RedGear = 35, GreenGear = 36, RedKey = 40, YellowKey = 45,
            Hammer = 55, Wrench = 56, WhiteKey = 100,
        },
    },
    Hospital = {
        Gates = {
            WhiteKey = {Present = {"EmptyVial", "GreenVial", "PurpleVial"}, Active = {"GreenVial", "PurpleVial"}},
        },
        Depends = {
            WhiteKey = {"GreenVial", "PurpleVial", "Hammer"},
        },
        Counters = {
            EmptyVial = 2,
        },
        Priority = {
            GreenKeycard = 10, BlueKeycard = 15, RedKeycard = 20, OrangeKeycard = 25,
            Hammer = 30, Plank = 35, Wrench = 36, EmptyVial = 40, GreenVial = 50, PurpleVial = 51,
            YellowKey = 60, WhiteKey = 100,
        },
    },
    Metro = {
        Gates = {
            BlueKeycard = {Present = {"Coin"}, Active = {"Coin"}},
            WhiteKey = {Active = {"BlueKeycard"}},
        },
        Depends = {
            BlueKeycard = {"Coin"},
            WhiteKey = {"BlueKeycard"},
        },
        Counters = {
            Coin = 2,
        },
        Priority = {
            GreenKey = 10, RedKey = 15, BlueKey = 20, OrangeKey = 25,
            Coin = 35, Hammer = 45, BlueKeycard = 55, Wrench = 60, WhiteKey = 100,
        },
    },
    Carnival = {
        Gates = {
            Mallet = {Active = {"YellowKey"}},
            Hammer = {Present = {"Mallet"}, Active = {"Mallet"}},
            WaterGun = {Active = {"BlueKey", "Wrench"}},
            KeyCode = {Present = {"WaterGun"}, Active = {"WaterGun"}},
            WhiteKey = {Active = {"OrangeKey"}},
        },
        Depends = {
            Mallet = {"YellowKey"},
            Hammer = {"Mallet"},
            WaterGun = {"BlueKey", "Wrench"},
            KeyCode = {"WaterGun"},
            WhiteKey = {"OrangeKey"},
        },
        Priority = {
            BlueKey = 10, GreenKey = 15, RedKey = 20, YellowKey = 25, OrangeKey = 30,
            Mallet = 35, Plank = 38, Hammer = 40, Wrench = 45, WaterGun = 50, KeyCode = 55, WhiteKey = 100,
        },
    },
    City = {
        Gates = {
            FireExtinguisher = {Active = {"Dynamite"}},
            KeyCode = {Active = {"FireExtinguisher", "Plank"}},
        },
        Depends = {
            FireExtinguisher = {"Dynamite"},
            KeyCode = {"FireExtinguisher", "Plank"},
        },
        Priority = {
            GreenKeycard = 10, RedKeycard = 15, OrangeKeycard = 20, BlueKeycard = 25,
            Plank = 35, Wrench = 40, Dynamite = 45, FireExtinguisher = 50, KeyCode = 100,
        },
    },
    Mall = {
        Gates = {
            Wrench = {Active = {"YellowKey"}},
            GreenKeycard = {Active = {"Wrench"}},
            Mirror = {Active = {"GreenKeycard"}},
            WhiteKey = {Present = {"Coin"}, Active = {"Coin"}},
        },
        Depends = {
            Wrench = {"YellowKey"},
            GreenKeycard = {"Wrench"},
            Mirror = {"GreenKeycard"},
            Coin = {"Crowbar", "Mirror"},
            WhiteKey = {"Coin"},
        },
        Counters = {
            Coin = 2,
        },
        Priority = {
            BlueKey = 10, GreenKey = 15, OrangeKey = 20, RedKey = 25,
            GreenKeycard = 30, Wrench = 35, Crowbar = 40, Plank = 42,
            Mirror = 44, Coin = 45, WhiteKey = 100,
        },
    },
    Outpost = {
        Gates = {
            FireExtinguisher = {Active = {"YellowKey", "GreenKey"}},
            Gas = {Active = {"FireExtinguisher"}},
            TankBullet = {Active = {"Wrench"}},
            BlueKeycard = {Present = {"Gas", "TankBullet"}, Active = {"Gas", "TankBullet"}},
        },
        Depends = {
            FireExtinguisher = {"YellowKey", "GreenKey"},
            Gas = {"FireExtinguisher"},
            TankBullet = {"Wrench"},
            BlueKeycard = {"Gas", "TankBullet"},
        },
        Priority = {
            BlueKey = 10, GreenKey = 15, OrangeKey = 20, RedKey = 25, YellowKey = 30,
            Wrench = 35, FireExtinguisher = 40, Gas = 50, TankBullet = 60, BlueKeycard = 100,
        },
    },
    Plant = {
        Gates = {
            Plank = {Active = {"YellowKey"}},
            Hammer = {Active = {"Plank"}},
            GreenVial = {Active = {"Hammer"}},
            PurpleVial = {Present = {"Battery"}, Active = {"Battery"}},
            Dynamite = {Present = {"GreenVial", "PurpleVial"}, Active = {"GreenVial", "PurpleVial"}},
            WhiteKey = {Present = {"Torch"}, Active = {"Torch"}},
            Mallet = {Present = {"Coin"}, Active = {"Coin"}},
        },
        Depends = {
            Plank = {"OrangeKeycard", "YellowKey"},
            Hammer = {"Plank"},
            GreenVial = {"Hammer"},
            PurpleVial = {"Battery"},
            Dynamite = {"GreenVial", "PurpleVial"},
            WhiteKey = {"Torch"},
            Mallet = {"Coin"},
        },
        Counters = {
            Battery = 2,
            Coin = 2,
        },
        Priority = {
            OrangeKeycard = 10, YellowKey = 15, Plank = 20, Hammer = 25, GreenVial = 30,
            GreenKeycard = 35, RedKey = 40, BlueKey = 41, Battery = 45, PurpleVial = 50,
            Dynamite = 60, Torch = 70, WhiteKey = 75, Coin = 80, Mallet = 90,
        },
    },
    Alleys = {
        Puzzle = "DigitCode",
        PuzzleBefore = {"WhiteKey"},
        Gates = {
            Screwdriver = {Active = {"YellowKey"}},
            WhiteKey = {Active = {"PurpleKey", "OrangeKey"}},
        },
        Depends = {
            Screwdriver = {"YellowKey", "GreenKey"},
            WhiteKey = {"PurpleKey", "OrangeKey"},
        },
        Priority = {
            OrangeKey = 10, Scissors = 15, BlueKey = 20, GreenKey = 25, RedKey = 30,
            YellowKey = 35, Screwdriver = 40, Mop = 45, PurpleKey = 50, KeyCode = 60, WhiteKey = 100,
        },
    },
    Store = {
        Gates = {
            YellowKey = {Active = {"RemoteControl"}},
            Ladder = {Active = {"YellowKey"}},
        },
        Depends = {
            YellowKey = {"RemoteControl"},
            Ladder = {"YellowKey", "RedKey", "BlueKey"},
        },
        Counters = {
            RemoteControl = 4,
            Battery = 2,
        },
        Priority = {
            GreenKey = 10, OrangeKey = 15, RedKey = 20, BlueKey = 25,
            Scissors = 28, RemoteControl = 30, YellowKey = 40, Ladder = 45, Carrot = 50,
            PurpleKey = 55, Battery = 100,
        },
    },
    Refinery = {
        Gates = {
            Screwdriver = {Active = {"SmokeGrenade", "RedKey"}},
            WhiteKey = {Active = {"PurpleKey"}},
        },
        Depends = {
            Screwdriver = {"RedKey", "SmokeGrenade"},
            WhiteKey = {"PurpleKey", "OrangeKey", "Scissors", "GreenKey", "Carrot"},
        },
        Priority = {
            Scissors = 10, GreenKey = 15, BlueKey = 20, RedKey = 25, YellowKey = 30,
            Screwdriver = 35, Carrot = 40, Battery = 45, GreenKeycard = 50,
            SmokeGrenade = 55, OrangeKey = 60, PurpleKey = 65, WhiteKey = 100,
        },
    },
    SafePlace = {
        Gates = {
            Hammer = {Active = {"BlueKey"}},
            FireExtinguisher = {Active = {"Hammer"}},
            Blowtorch = {Active = {"PurpleKey", "FireExtinguisher"}},
            YellowKey = {Active = {"ElevatorKey"}},
            WhiteKey = {Active = {"YellowKey", "RedKey"}},
        },
        Depends = {
            Hammer = {"BlueKey"},
            FireExtinguisher = {"Hammer"},
            YellowKey = {"ElevatorKey"},
            Blowtorch = {"PurpleKey", "FireExtinguisher", "Screwdriver", "Ladder"},
            WhiteKey = {"YellowKey", "RedKey"},
        },
        Priority = {
            Screwdriver = 10, Ladder = 15, OrangeKey = 18, GreenKey = 20, RedKey = 22,
            BlueKey = 24, YellowKey = 26, FireExtinguisher = 30, Hammer = 35,
            PurpleKey = 40, ElevatorKey = 45, Blowtorch = 50, WhiteKey = 100,
        },
    },
    Sewers = {
        Gates = {
            Screwdriver = {Active = {"Plank", "OrangeKey"}},
            Mop = {Active = {"WhiteGear", "Screwdriver", "YellowKey"}},
            WhiteKey = {Present = {"Mop"}, Active = {"Mop"}},
        },
        Depends = {
            Screwdriver = {"Plank", "OrangeKey"},
            Mop = {"GreenKey", "WhiteGear", "Screwdriver", "YellowKey"},
            WhiteKey = {"Mop"},
        },
        Counters = {
            WhiteGear = 2,
        },
        Priority = {
            GreenKey = 10, OrangeKey = 15, Plank = 20, Screwdriver = 25, WhiteGear = 30,
            BlueKey = 40, YellowKey = 45, PurpleKey = 48, Mop = 50, RedKey = 55, WhiteKey = 100,
        },
    },
    Factory = {
        Gates = {
            Screwdriver = {Active = {"PurpleKey"}},
            OrangeKey = {Active = {"YellowKey"}},
        },
        Depends = {
            Screwdriver = {"PurpleKey", "BlueKey", "RedKey"},
            OrangeKey = {"YellowKey", "RedKey", "BlueKey", "GreenKey"},
        },
        Counters = {
            WoodenSword = 3,
        },
        Priority = {
            BlueKey = 10, GreenKey = 15, RedKey = 20, YellowKey = 25,
            Ladder = 30, Scissors = 35, Shovel = 40, Axe = 45, FireExtinguisher = 50,
            PurpleKey = 55, Screwdriver = 60, OrangeKey = 65, WoodenSword = 100,
        },
    },
    Port = {
        Gates = {
            Plank = {Active = {"PurpleKey"}},
            GrapplingHook = {Active = {"YellowKey"}},
        },
        Depends = {
            Plank = {"PurpleKey"},
            GrapplingHook = {"RedKey", "YellowKey"},
        },
        Counters = {
            Battery = 4,
        },
        Priority = {
            RedKey = 10, BlueKey = 15, OrangeKey = 20, GreenKey = 25, PurpleKey = 30,
            Plank = 35, YellowKey = 40, GrapplingHook = 45, Shovel = 50, Battery = 100,
        },
    },
    Ship = {
        Puzzle = "ColorCode",
        PuzzleBefore = {"WhiteKey"},
        Gates = {
            WhiteKey = {Active = {"YellowKey"}},
            Screwdriver = {Active = {"PurpleKey"}},
            Wrench = {Active = {"OrangeKey"}},
        },
        Depends = {
            WhiteKey = {"YellowKey"},
            Screwdriver = {"PurpleKey"},
            Wrench = {"OrangeKey"},
        },
        Priority = {
            BlueKey = 10, GreenKey = 15, OrangeKey = 20, RedKey = 25, PurpleKey = 30,
            Screwdriver = 35, Wrench = 40, YellowKey = 45, WhiteKey = 100,
        },
    },
    Docks = {
        Puzzle = "RomanCode",
        PuzzleBefore = {"WhiteKey"},
        Gates = {
            BlueKey = {Active = {"PurpleKey"}},
            Hammer = {Active = {"OrangeKey"}},
            WhiteKey = {Active = {"YellowKey", "GreenKey", "Plank"}},
        },
        Depends = {
            BlueKey = {"PurpleKey"},
            Hammer = {"OrangeKey"},
            Plank = {"BlueKey", "Hammer"},
            WhiteKey = {"YellowKey", "GreenKey", "Plank"},
        },
        Priority = {
            BlueKey = 10, GreenKey = 15, OrangeKey = 20, RedKey = 25,
            Hammer = 30, Plank = 35, Candle = 40, TNT = 42, YellowKey = 45,
            PurpleKey = 50, WhiteKey = 100,
        },
    },
    Temple = {
        Puzzle = "ShapeWheel",
        PuzzleBefore = {"WhiteKey"},
        Gates = {
            Hammer = {Active = {"YellowKey"}},
            WhiteKey = {Active = {"PurpleKey", "Shovel", "Plank", "Candle"}},
        },
        Depends = {
            Hammer = {"RedKey", "YellowKey"},
            Plank = {"Hammer"},
            WhiteKey = {"PurpleKey", "Shovel", "Plank", "Candle"},
        },
        Priority = {
            BlueKey = 10, GreenKey = 15, OrangeKey = 20, RedKey = 25,
            Shovel = 30, YellowKey = 35, Hammer = 40, Plank = 45, Candle = 50,
            Gas = 55, PurpleKey = 60, WhiteKey = 100,
        },
    },
    Camp = {
        Puzzle = "LightCircle",
        Gates = {
            TNT = {Active = {"PurpleKey"}},
            ElevatorKey = {Active = {"YellowKey", "RedKey"}},
        },
        Depends = {
            Ladder = {"Shovel"},
            Rope = {"GreenKey"},
            TNT = {"PurpleKey"},
            ElevatorKey = {"YellowKey", "RedKey"},
        },
        Priority = {
            GreenKey = 10, OrangeKey = 15, BlueKey = 20, RedKey = 25,
            Ladder = 30, Shovel = 35, PurpleKey = 40, TNT = 45, Rope = 50,
            YellowKey = 55, ElevatorKey = 100,
        },
    },
    DistortedMemory = {
        Gates = {
            DinosaurToy = {Active = {"Wrench"}},
            RobotToy = {Active = {"Hammer"}},
            KeyCode = {Active = {"YellowKey"}},
            WhiteKey = {Present = {"DinosaurToy", "RobotToy"}, Active = {"DinosaurToy", "RobotToy"}},
        },
        Depends = {
            DinosaurToy = {"Wrench"},
            RobotToy = {"Hammer"},
            KeyCode = {"YellowKey"},
            WhiteKey = {"DinosaurToy", "RobotToy"},
        },
        Priority = {
            GreenKey = 10, RedKey = 15, BlueKey = 20, OrangeKey = 25,
            Wrench = 30, Hammer = 35, Plank = 40, YellowKey = 45,
            DinosaurToy = 50, RobotToy = 51, KeyCode = 60, WhiteKey = 100,
        },
    },
    WinterHoliday = {
        Counters = {
            Presents = 5,
        },
        Priority = {
            Shovel = 10, WhiteKey = 15, Carrot = 20, Dreidel = 25,
            FencingSword = 30, RobotToy = 35, Book = 40, Presents = 100,
        },
    },
    Heist = {
        Gates = {
            Barbell = {Active = {"YellowKey"}},
            RedKey = {Active = {"PurpleKey"}},
            Pie = {Active = {"Barbell", "Crowbar", "RedKey", "SprayCan"}},
        },
        Depends = {
            Barbell = {"YellowKey"},
            RedKey = {"PurpleKey"},
            Pie = {"Barbell", "Crowbar", "RedKey", "SprayCan"},
        },
        Priority = {
            OrangeKey = 10, GreenKey = 15, BlueKey = 20, Scissors = 25,
            Crowbar = 30, PurpleKey = 35, YellowKey = 40, Barbell = 45,
            RedKey = 50, SprayCan = 55, Pie = 100,
        },
    },
    Distraction = {
        Counters = {
            TNT = 3,
        },
        Gates = {
            GreenKey = {Active = {"YellowKey"}},
            Screwdriver = {Active = {"PurpleKey"}},
        },
        Depends = {
            GreenKey = {"YellowKey"},
            Screwdriver = {"PurpleKey"},
        },
        Priority = {
            OrangeKey = 10, RedKey = 15, BlueKey = 20, Pipe = 25,
            Candle = 30, YellowKey = 35, GreenKey = 40, PurpleKey = 45,
            Screwdriver = 50, TNT = 100,
        },
    },
    Breakout = {
        Puzzle = "BreakoutCircles",
        Counters = {
            RedWire = 1, GreenWire = 1, BlueWire = 1, YellowWire = 1,
        },
        Priority = {
            RedWire = 10, GreenWire = 11, BlueWire = 12, YellowWire = 13,
            FrontDoorKey = 60, MilitaryKnife = 100,
        },
    },
    Mansion = {
        Gates = {
            PurpleKey = {Active = {"RemoteControl"}},
            WhiteKey = {
                Present = {"DayPaintBucket", "NightPaintBucket", "SunsetPaintBucket"},
                Active = {"DayPaintBucket", "NightPaintBucket", "SunsetPaintBucket"},
            },
        },
        Depends = {
            PurpleKey = {"RemoteControl"},
            WhiteKey = {"DayPaintBucket", "NightPaintBucket", "SunsetPaintBucket"},
        },
        Counters = {
            Book = 3,
        },
        Priority = {
            Book = 10, GreenWire = 20, YellowWire = 21, RedKey = 30,
            BlueKey = 40, RemoteControl = 45, PurpleKey = 50,
            DayPaintBucket = 60, NightPaintBucket = 61, SunsetPaintBucket = 62,
            WhiteKey = 100,
        },
    },
    DistortedHoliday = {
        Gates = {
            YellowKey = {Active = {"OrangeKey"}},
            RedKey = {Active = {"Ladder"}},
            PurpleKey = {Active = {"Shovel"}},
            BlackKey = {Active = {"RedKey", "PurpleKey"}},
            OrangeKey = {Active = {"Hammer"}},
            Torch = {Active = {"BlackKey"}},
        },
        Depends = {
            YellowKey = {"OrangeKey"},
            RedKey = {"Ladder"},
            PurpleKey = {"Shovel"},
            BlackKey = {"RedKey", "PurpleKey"},
            OrangeKey = {"Hammer"},
            Torch = {"BlackKey"},
        },
        Counters = {
            Torch = 3,
        },
        Priority = {
            GreenKey = 10, BlueKey = 15, Ladder = 20, Shovel = 25,
            PurpleKey = 30, RedKey = 35, BlackKey = 40, Hammer = 45,
            OrangeKey = 50, YellowKey = 55, Scissors = 60, Snowball = 65,
            Torch = 100,
        },
    },
    HolidaySpirit = {
        Counters = {
            Strawberry = 3,
            Prop = 10,
            Clothing = 7,
        },
        Priority = {
            Ticket = 10, PurpleKey = 15, PremiumTicket = 20, RedKey = 25,
            BlueKey = 30, GreenKey = 35, OrangeKey = 40, Ladder = 45,
            Wrench = 50, Axe = 55, Box = 60, Katana = 65,
            Strawberry = 75, Prop = 90, Clothing = 100,
        },
    },
    TheHunt = {
        Puzzle = "HuntSequence",
        Gates = {
            ElevatorKey = {Active = {"RedKey"}},
        },
        Depends = {
            ElevatorKey = {"RedKey"},
        },
        Priority = {
            YellowKey = 10, BlueKey = 15, RedKey = 30,
            ElevatorKey = 40, GreenKey = 50,
        },
    },
    Lab = {
        Puzzle = "ReactorLevers",
        Depends = {
            BlueKeycard = {"Wrench"},
            Pipe = {"Screwdriver"},
            WaterGun = {"Hammer"},
            Mop = {"Dynamite"},
        },
        Priority = {
            GreenKey = 10, PurpleKey = 15, YellowKey = 20, Wrench = 25,
            BlueKey = 30, RedKeycard = 35, OrangeKeycard = 40, BlueKeycard = 45,
            Dynamite = 60, Screwdriver = 65, Hammer = 70, WaterGun = 75,
            Pipe = 76, WoodenSword = 77, Mop = 80,
        },
    },
}

mapProfiles["The Safe Place"] = mapProfiles.SafePlace
mapProfiles["Distorted Memory"] = mapProfiles.DistortedMemory
mapProfiles["Winter Holiday"] = mapProfiles.WinterHoliday
mapProfiles["Distorted Holiday"] = mapProfiles.DistortedHoliday
mapProfiles["Holiday Spirit"] = mapProfiles.HolidaySpirit
mapProfiles["The Hunt"] = mapProfiles.TheHunt

function cleanAssetId(value)
    return tostring(value or ""):match("%d+") or ""
end

function particleColor(item)
    local emitter = item:FindFirstChildWhichIsA("ParticleEmitter", true)
    return emitter and tostring(emitter.Color) or nil
end

colorIds = {
    ["0 0 1 1 0 1 0 1 1 0 "] = "Blue",
    ["0 1 0.333333 0 0 1 1 0.333333 0 0 "] = "Orange",
    ["0 0 1 0 0 1 0 1 0 0 "] = "Green",
    ["0 1 0 0 0 1 1 0 0 0 "] = "Red",
    ["0 1 1 0 0 1 1 1 0 0 "] = "Yellow",
    ["0 1 1 1 0 1 1 1 1 0 "] = "White",
    ["0 0.666667 0.333333 1 0 1 0.666667 0.333333 1 0 "] = "Purple",
    ["0 0.333333 0.666667 0 0 1 0.333333 0.666667 0 0 "] = "Green",
}

brickColors = {
    ["Lime green"] = "Green",
    ["Really red"] = "Red",
    ["Toothpaste"] = "Blue",
    ["Neon orange"] = "Orange",
    ["Gold"] = "Yellow",
    ["Alder"] = "Purple",
    ["Institutional white"] = "White",
    ["Shamrock"] = "Green",
    ["Persimmon"] = "Red",
}

