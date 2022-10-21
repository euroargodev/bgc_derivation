function cdom = cdomcalc(raw, dark, scale)
    cdom = (raw - dark) * scale;
end
