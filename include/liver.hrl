-define(DEFAULT_RULES, #{
    %% common rules
    required                    => liver_livr_rules,
    not_empty                   => liver_livr_rules,
    not_empty_list              => liver_livr_rules,
    any_object                  => liver_livr_rules,

    %% string rules
    string                      => liver_livr_rules,
    eq                          => liver_livr_rules,
    one_of                      => liver_livr_rules,
    max_length                  => liver_livr_rules,
    min_length                  => liver_livr_rules,
    length_between              => liver_livr_rules,
    length_equal                => liver_livr_rules,
    like                        => liver_livr_rules,

    %% numeric rules
    integer                     => liver_livr_rules,
    positive_integer            => liver_livr_rules,
    decimal                     => liver_livr_rules,
    positive_decimal            => liver_livr_rules,
    max_number                  => liver_livr_rules,
    min_number                  => liver_livr_rules,
    number_between              => liver_livr_rules,

    %% special rules
    email                       => liver_livr_rules,
    url                         => liver_livr_rules,
    iso_date                    => liver_livr_rules,
    equal_to_field              => liver_livr_rules,

    %% meta rules
    nested_object               => liver_livr_rules,
    list_of                     => liver_livr_rules,
    list_of_objects             => liver_livr_rules,
    list_of_different_objects   => liver_livr_rules,
    'or'                        => liver_livr_rules,

    %% modifiers (previously - "filter rules")
    trim                        => liver_livr_rules,
    to_lc                       => liver_livr_rules,
    to_uc                       => liver_livr_rules,
    remove                      => liver_livr_rules,
    leave_only                  => liver_livr_rules,
    default                     => liver_livr_rules
}).

-define(DEFAULT_LIVR_ERRORS, #{
    format_error            => <<"FORMAT_ERROR">>,
    required                => <<"REQUIRED">>,
    cannot_be_empty         => <<"CANNOT_BE_EMPTY">>,
    not_allowed_value       => <<"NOT_ALLOWED_VALUE">>,
    too_long                => <<"TOO_LONG">>,
    too_short               => <<"TOO_SHORT">>,
    wrong_format            => <<"WRONG_FORMAT">>,
    not_integer             => <<"NOT_INTEGER">>,
    not_positive_integer    => <<"NOT_POSITIVE_INTEGER">>,
    not_decimal             => <<"NOT_DECIMAL">>,
    not_positive_decimal    => <<"NOT_POSITIVE_DECIMAL">>,
    too_high                => <<"TOO_HIGH">>,
    too_low                 => <<"TOO_LOW">>,
    not_number              => <<"NOT_NUMBER">>
}).