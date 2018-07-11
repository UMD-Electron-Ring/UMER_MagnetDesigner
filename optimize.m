function optimize(min_a, max_a, step)
  for a=min_a:step:max_a
    DesignMagnetFunction(a);
    MakeSextupolePCB(true, a);
    MakeSextupolePCB(false, a);
  end
end
