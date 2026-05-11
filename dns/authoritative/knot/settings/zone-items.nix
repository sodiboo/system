{ lib, ... }:
{
  options =
    builtins.mapAttrs
      (
        _: type:
        lib.mkOption {
          type = lib.types.nullOr type;
          default = null;
        }
      )
      {
        storage = lib.types.str;

        master = lib.types.listOf lib.types.str;
        ddns-master = lib.types.str;

        notify = lib.types.listOf lib.types.str;
        acl = lib.types.listOf lib.types.str;

        semantic-checks = lib.types.enum [
          false
          "soft"
          true
        ];
        default-ttl = lib.types.ints.positive;

        zonefile-sync = lib.types.addCheck lib.types.int (x: x >= -1) // {
          name = "unsigned-or-minus-one";
          description = "unsigned integer or -1";
          descriptionClass = "conjunction";
        };

        zonefile-load = lib.types.enum [
          "none"
          "difference"
          "difference-no-serial"
          "whole"
        ];

        journal-content = lib.types.enum [
          "none"
          "changes"
          "all"
        ];

        catalog-role = lib.types.enum [
          "none"
          "interpret"
          "generate"
          "member"
        ];
        catalog-template = lib.types.listOf lib.types.str;
        catalog-zone = lib.types.str;
        catalog-group = lib.types.str;
      };
}
