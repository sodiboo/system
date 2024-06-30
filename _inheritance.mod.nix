{
  merge,
  configs,
  ...
}: {
  oxygen = configs.universal;
  sodium = merge configs.universal configs.personal;
  lithium = merge configs.universal configs.personal;
  nitrogen = merge configs.universal configs.personal;
}
