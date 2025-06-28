rec {
  getString = envName: descr: default:
    let
      envVal = builtins.getEnv envName;
    in
    if envVal == "" || envVal == default
    then
      default
    else
      builtins.trace "Overriding option \"${descr}\" with \"${envVal}\" due to set \"${envName}\"" envVal;
  getBool = envName: descr: default:
    let
      str = getString envName descr (toString default);
    in
    str == "1";
}
