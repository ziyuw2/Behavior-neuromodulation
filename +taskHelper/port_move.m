function port_move(Info, movement, ARDU)
    writeDigitalPin(ARDU, Info.PIN.motorDaq, 1);
    for step = 1:length(movement)
        writePosition(Info.servo, movement(step));
    end
    writeDigitalPin(ARDU, Info.PIN.motorDaq, 0);
end
