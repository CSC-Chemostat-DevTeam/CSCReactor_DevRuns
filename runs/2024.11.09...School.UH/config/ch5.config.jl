## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# COMMONS

# CHEMOSTATS
CH5 = Dict(
    # EXTRAS
    "ch.name" => "CH5",
    "run.dry" => false,
    
    # PIN LAYOUT
    "stirrel.pin" => STIRREL_PIN,
    "pump.air.in.pin" => PUMP_3_PIN,
    "pump.medium.out.pin" => PUMP_6_PIN,
    "pump.medium.in.pin" => PUMP_7_PIN,
    "laser.pin" => CH5_LASER_PIN,
    "led1.pin" => CH5_CONTROL_LED_PIN,
    "led2.pin" => CH5_VIAL_LED_PIN,
    
    # CONFIG
    "vial.working_volume" => 25.0, # mL #TODO [MEASSURED]
    
    "pump.medium.in.per_pulse_volume" => 0.054, # mL #TODO [MEASSURED]
    "pump.medium.in.pulse_duration" => 50.0, # ms
    
    "pump.medium.out.pulse_duration" => 150.0, # ms

    "laser.pwm.max" => 210,
    
    # MAIN CONTROL
    "dilution.target" => 0.0, # 1/h

    # STATE
    "pump.medium.in.enable" => true,
    "pump.medium.in.pulse_period.min" => 0,
    "pump.medium.in.pulse_duration" => 100,
    "pump.medium.in.pulse_pwm0" => 255,
    "pump.medium.in.pulse_period.target" => 0,
    
    "pump.medium.out.enable" => true, 
    "pump.medium.out.pulse_period.min" => 100,
    "pump.medium.out.pulse_duration" => 100,
    "pump.medium.out.pulse_pwm0" => 255,
    "pump.medium.out.pulse_period.target" => nothing,
    
    "stirrel.enable" => true, 
    "stirrel.pulse_period.min" => 3,
    "stirrel.pulse_duration" => 900,
    "stirrel.pulse_pwm0" => 255,
    "stirrel.pulse_period.target" => nothing,
    
    "pump.air.in.enable" => true,
    "pump.air.in.pulse_period.min" => 0,
    "pump.air.in.pulse_duration" => 100,
    "pump.air.in.in.pulse_pwm0" => 255,
    "pump.air.in.pulse_period.target" => nothing,
)

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
return nothing