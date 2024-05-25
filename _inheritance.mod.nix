{
  merge,
  configs,
  ...
}: {
  oxygen = configs.universal;
  sodium = merge configs.universal configs.personal;
  lithium = merge configs.universal configs.personal;
}
