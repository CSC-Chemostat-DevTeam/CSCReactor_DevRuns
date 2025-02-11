## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# COMMONS

# CHEMOSTATS
CH2 = Dict(
    # EXTRAS
    "ch.name" => "CH2",
    "run.dry" => false,
    
    # PIN LAYOUT
    "stirrel.pin" => STIRREL_PIN,
    "pump.air.in.pin" => nothing,
    "pump.medium.out.pin" => PUMP_4_PIN,
    "pump.medium.in.pin" => PUMP_5_PIN,
    "laser.pin" => CH2_LASER_PIN,
    "led1.pin" => CH2_CONTROL_LED_PIN,
    "led2.pin" => CH2_VIAL_LED_PIN,
    
    # CONFIG
    "vial.working_volume" => 25.0, # mL #TODO [MEASSURED]
    
    "pump.medium.in.per_pulse_volume" => 0.02, # mL
    "pump.medium.in.pulse_duration" => 50.0, # ms
    
    "pump.medium.out.pulse_duration" => 150.0, # ms

    "laser.pwm.max" => 210,
    
    # MAIN CONTROL
    "dilution.target" => 1000.0, # 1/h

    # STATE
    "pump.medium.in.enable" => true,
    "pump.medium.in.pulse_period.min" => 0,
    "pump.medium.in.pulse_period.target" => 0,
    
    "pump.medium.out.enable" => true,
    "pump.medium.out.pulse_period.min" => 0,
    "pump.medium.out.pulse_period.target" => nothing,

    "stirrel.enable" => false, # CH1 on control
    "stirrel.pulse_period.min" => 3,
    "stirrel.pulse_period.target" => nothing,

    "pump.air.in.enable" => false, # CH1 on control
    "pump.air.in.pulse_period.min" => 0,
    "pump.air.in.pulse_period.target" => nothing,
)

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
return nothing