function optimize(min_a, max_a, step, radius)
  for a=min_a:step:max_a
    DesignMagnetFunction(a, radius);
    MakeSextupolePCB(true, a, radius);
    MakeSextupolePCB(false, a, radius);
  end
end
