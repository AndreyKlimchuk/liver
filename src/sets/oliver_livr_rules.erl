-module(oliver_livr_rules).

%% API
%% common rules
-export([required/4]).
-export([not_empty/4]).
-export([not_empty_list/4]).
-export([any_object/4]).

%% string rules
-export([string/4]).
-export([eq/4]).
-export([one_of/4]).
-export([max_length/4]).
-export([min_length/4]).
-export([length_between/4]).
-export([length_equal/4]).
-export([like/4]).

%% numeric rules
-export([integer/4]).
-export([positive_integer/4]).
-export([decimal/4]).
-export([positive_decimal/4]).
-export([max_number/4]).
-export([min_number/4]).
-export([number_between/4]).

%% special rules
-export([email/4]).
-export([url/4]).
-export([iso_date/4]).
-export([equal_to_field/4]).

%% meta rules
-export([nested_object/4]).
-export([list_of/4]).
-export([list_of_objects/4]).
-export([list_of_different_objects/4]).
-export(['or'/4]).

%% modifiers (previously - "filter rules")
-export([trim/4]).
-export([to_lc/4]).
-export([to_uc/4]).
-export([remove/4]).
-export([leave_only/4]).
-export([default/4]).

-include("oliver.hrl").

%% API
%% common rules
required(_Args, <<>>, _Opts, _InData) ->
    {error, format_error};
required(_Args, null, _Opts, _InData) ->
    {error, format_error};
required(_Args, undefined, _Opts, _InData) ->
    {error, format_error};
required(_Args, Value, _Opts, _InData) ->
    {ok, Value}.

not_empty(_Args, Value, _Opts, _InData) ->
    case Value of
        <<>> -> {error, cannot_be_empty};
        _    -> {ok, Value}
    end.

not_empty_list(_Args, Value, _Opts, _InData) ->
    case Value of
        [_|_]   -> {ok, Value};
        []      -> {error, cannot_be_empty}
    end.

any_object(_Args, Value, _Opts, _InData) ->
    case Value of
        #{}     -> {ok, Value};
        [{}]    -> {ok, Value};
        [_|_]   -> proplist(Value);
        []      -> {error, format_error}
    end.

%% string rules
string(_Args, Value, _Opts, _InData) when is_binary(Value) ->
    {ok, Value};
string(_Args, Value, Opts, InData) when is_number(Value) ->
    Value2 = number_to_binary(Value),
    string(_Args, Value2, Opts, InData);
string(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

eq([Equivalent], Value, Opts, InData) ->
    eq(Equivalent, Value, Opts, InData);
eq(Value, Value, _Opts, _InData) ->
    {ok, Value};
eq(Equivalent, Value, _Opts, _InData) when Equivalent == Value ->
    Value2 = trunc(Value),
    {ok, Value2};
eq(Equivalent, Value, Opts, InData) when is_binary(Equivalent), is_number(Value) ->
    Value2 = number_to_binary(Value),
    eq(Equivalent, Value2, Opts, InData);
eq(Equivalent, Value, Opts, InData) when is_number(Equivalent), is_binary(Value) ->
    try binary_to_number(Value) of
        Value2 ->
            eq(Equivalent, Value2, Opts, InData)
    catch
        error:badarg ->
            {error, not_allowed_value}
    end;
eq(Equivalent, Value, _Opts, _InData) when is_list(Equivalent); is_list(Value) ->
    {error, format_error};
eq(_Equivalent, _Value, _Opts, _InData) ->
    {error, not_allowed_value}.

one_of([List|_], Value, Opts, InData) when is_list(List) ->
    one_of(List, Value, Opts, InData);
one_of([Equivalent|List], Value, Opts, InData) ->
    case eq(Equivalent, Value, Opts, InData) of
        {error, not_allowed_value} ->
            one_of(List, Value, Opts, InData);
        {ok, Value} ->
            {ok, Value}
    end;
one_of([], _Value, _Opts, _InData) ->
    {error, not_allowed_value};
one_of(Equivalent, Value, Opts, InData) ->
    eq(Equivalent, Value, Opts, InData).

max_length([MaxLength|_], Value, Opts, InData) ->
    max_length(MaxLength, Value, Opts, InData);
max_length(MaxLength, Value, _Opts, _InData) when is_binary(Value) ->
    StrValue = unicode:characters_to_list(Value),
    case length(StrValue) > MaxLength of
        false   -> {ok, Value};
        true    -> {error, too_long}
    end;
max_length(MaxLength, Value, Opts, InData) when is_number(Value) ->
    Value2 = number_to_binary(Value),
    max_length(MaxLength, Value2, Opts, InData);
max_length(_MaxLength, _Value, _Opts, _InData) ->
    {error, format_error}.

min_length([MinLength|_], Value, _Opts, _InData) ->
    min_length(MinLength, Value, _Opts, _InData);
min_length(MinLength, Value, _Opts, _InData) when is_binary(Value) ->
    StrValue = unicode:characters_to_list(Value),
    case length(StrValue) < MinLength of
        false   -> {ok, Value};
        true    -> {error, too_short}
    end;
min_length(MinLength, Value, _Opts, _InData) when is_number(Value) ->
    Value2 = number_to_binary(Value),
    min_length(MinLength, Value2, _Opts, _InData);
min_length(_MinLength, _Value, _Opts, _InData) ->
    {error, format_error}.

length_between([[Min, Max]|_], Value, _Opts, _InData) ->
    length_between([Min, Max], Value, _Opts, _InData);
length_between([Min, Max|_], Value, _Opts, _InData) when is_binary(Value) ->
    StrValue = unicode:characters_to_list(Value),
    Length = length(StrValue),
    if
        Length < Min    -> {error, too_short};
        Length > Max    -> {error, too_long};
        true            -> {ok, Value}
    end;
length_between([Min, Max|_], Value, Opts, InData) when is_number(Value) ->
    Value2 = number_to_binary(Value),
    length_between([Min, Max], Value2, Opts, InData);
length_between(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

length_equal([Length|_], Value, Opts, InData) ->
    length_equal(Length, Value, Opts, InData);
length_equal(Length, Value, _Opts, _InData) when is_binary(Value) ->
    StrValue = unicode:characters_to_list(Value),
    ActualLength = length(StrValue),
    if
        ActualLength < Length   -> {error, too_short};
        ActualLength > Length   -> {error, too_long};
        ActualLength == Length  -> {ok, Value}
    end;
length_equal(Length, Value, Opts, InData) when is_number(Value) ->
    Value2 = number_to_binary(Value),
    min_length(Length, Value2, Opts, InData);
length_equal(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

like(Args, Value, _Opts, _InData) when is_binary(Value); is_number(Value) ->
    Value2 = to_binary(Value),
    {Pattern, ReOpts} = case Args of
        [RegEx, <<"i">>|_]  -> {RegEx, [unicode, caseless]};
        [RegEx|_]           -> {RegEx, [unicode]};
        RegEx               -> {RegEx, [unicode]}
    end,
    case re:compile(Pattern, ReOpts) of
        {ok, MP} ->
            case re:run(Value2, MP) of
                nomatch -> {error, wrong_format};
                _       -> {ok, Value2}
            end;
        {error, _} ->
            {error, invalid_pattern}
    end;
like(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

%% numeric rules
integer(_Args, Value, _Opts, _InData) when is_integer(Value) ->
    {ok, Value, _Opts, _InData};
integer(_Args, Value, _Opts, _InData) when is_binary(Value) ->
    convert(binary_to_integer, Value, {error, not_integer});
integer(_Args, Value, _Opts, _InData) when is_float(Value) ->
    {error, not_integer};
integer(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

positive_integer(_Args, Value, _Opts, _InData) when is_integer(Value), Value > 0 ->
    {ok, Value};
positive_integer(_Args, Value, _Opts, _InData) when is_binary(Value) ->
    case convert(binary_to_integer, Value, {error, not_positive_integer}) of
        {ok, Value2} = OK when Value2 > 0 ->
            OK;
        _Err ->
            {error, not_positive_integer}
    end;
positive_integer(_Args, Value, _Opts, _InData) when is_integer(Value); is_float(Value) ->
    {error, not_positive_integer};
positive_integer(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

decimal(_Args, Value, _Opts, _InData) when is_float(Value) ->
    {ok, Value};
decimal(_Args, Value, _Opts, _InData) when is_binary(Value) ->
    convert(binary_to_float, Value, {error, not_decimal});
decimal(_Args, Value, _Opts, _InData) when is_integer(Value) ->
    {error, not_decimal};
decimal(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

positive_decimal(_Args, Value, _Opts, _InData) when is_float(Value), Value > 0 ->
    {ok, Value};
positive_decimal(_Args, Value, _Opts, _InData) when is_binary(Value) ->
    case convert(binary_to_float, Value, {error, not_positive_decimal}) of
        {ok, Value2} = OK when Value2 > 0 ->
            OK;
        _Err ->
            {error, not_positive_decimal}
    end;
positive_decimal(_Args, Value, _Opts, _InData) when is_float(Value); is_integer(Value) ->
    {error, not_positive_decimal};
positive_decimal(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

max_number([Max|_], Value, Opts, InData) ->
    max_number(Max, Value, Opts, InData);
max_number(Max, Value, _Opts, _InData) when is_number(Value) ->
    case Max >= Value of
        true ->
            {ok, Value};
        false ->
            {error, too_high}
    end;
max_number(Max, Value, _Opts, _InData) when is_binary(Value) ->
    try binary_to_number(Value) of
        Value2 when Max >= Value2 ->
            {ok, Value2};
        _Value2 ->
            {error, too_high}
    catch
        error:badarg ->
            {error, not_number}
    end;
max_number(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

min_number([Min|_], Value, Opts, InData) ->
    min_number(Min, Value, Opts, InData);
min_number(Min, Value, _Opts, _InData) when is_number(Value) ->
    case Min =< Value of
        true ->
            {ok, Value};
        false ->
            {error, too_low}
    end;
min_number(Min, Value, _Opts, _InData) when is_binary(Value) ->
    try binary_to_number(Value) of
        Value2 when Min =< Value2 ->
            {ok, Value2};
        _Value2 ->
            {error, too_low}
    catch
        error:badarg ->
            {error, not_number}
    end;
min_number(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

number_between([[Min, Max]|_], Value, Opts, InData) ->
    number_between([Min, Max], Value, Opts, InData);
number_between([Min, Max|_], Value, _Opts, _InData) when is_number(Value) ->
    case {Min =< Value, Value =< Max} of
        {true, true}    -> {ok, Value};
        {false, true}   -> {error, too_low};
        {true, false}   -> {error, too_high}
    end;
number_between([Min, Max|_], Value, _Opts, _InData) when is_binary(Value) ->
    try binary_to_number(Value) of
        Value2 when Min =< Value2, Value2 =< Max ->
            {ok, Value2};
        Value2 when Min > Value2 ->
            {error, too_low};
        Value2 when Max < Value2 ->
            {error, too_high}
    catch
        _:_ ->
            {error, not_number}
    end;
number_between(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

%% special rules
email(_Args, Value, _Opts, _InData) ->
    %% TODO
    {ok, Value}.

url(_Args, Value, _Opts, _InData) ->
    %% TODO
    {ok, Value}.

iso_date(_Args, Value, _Opts, _InData) ->
    %% TODO
    {ok, Value}.

equal_to_field(_Args, Value, _Opts, _InData) ->
    %% TODO
    {ok, Value}.

%% meta rules
nested_object(Args, Value, Opts, _InData) ->
    oliver:validate(Args, Value, Opts).

list_of(_Args, Value, _Opts, _InData) when is_list(Value) ->
    %% TODO
    {ok, Value};
list_of(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

list_of_objects(_Args, Value, _Opts, _InData) when is_list(Value) ->
    %% TODO
    {ok, Value};
list_of_objects(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

list_of_different_objects(_Args, Value, _Opts, _InData) when is_list(Value) ->
    %% TODO
    {ok, Value};
list_of_different_objects(_Args, _Value, _Opts, _InData) ->
    {error, format_error}.

'or'(_Args, Value, _Opts, _InData) ->
    %% TODO
    {ok, Value}.

%% modifiers (previously - "filter rules")
trim(_Args, Value, _Opts, _InData) when is_binary(Value) ->
    Value2 = oliver_bstring:trim(Value),
    {ok, Value2};
trim(Args, Value, Opts, InData) when is_number(Value) ->
    Value2 = number_to_binary(Value),
    trim(Args, Value2, Opts, InData);
trim(_Args, Value, _Opts, _InData) ->
    {ok, Value}.

to_lc(_Args, Value, _Opts, _InData) when is_binary(Value) ->
    Value2 = oliver_bstring:to_lower(Value),
    {ok, Value2};
to_lc(Args, Value, Opts, InData) when is_number(Value) ->
    Value2 = number_to_binary(Value),
    to_lc(Args, Value2, Opts, InData);
to_lc(_Args, Value, _Opts, _InData) ->
    {ok, Value}.

to_uc(_Args, Value, _Opts, _InData) when is_binary(Value) ->
    Value2 = oliver_bstring:to_upper(Value),
    {ok, Value2};
to_uc(Args, Value, Opts, InData) when is_number(Value) ->
    Value2 = number_to_binary(Value),
    to_uc(Args, Value2, Opts, InData);
to_uc(_Args, Value, _Opts, _InData) ->
    {ok, Value}.

remove([Pattern|_], Value, _Opts, _InData) ->
    remove(Pattern, Value, _Opts, _InData);
remove(Pattern, Value, _Opts, _InData) when is_binary(Pattern), is_binary(Value) ->
    Value2 = oliver_bstring:remove_chars(Value, Pattern),
    {ok, Value2};
remove(_Args, Value, _Opts, _InData) ->
    {ok, Value}.

leave_only([Pattern|_], Value, Opts, InData) ->
    leave_only(Pattern, Value, Opts, InData);
leave_only(Pattern, Value, _Opts, _InData) when is_binary(Pattern), is_binary(Value) ->
    Value2 = oliver_bstring:leave_chars(Value, Pattern),
    {ok, Value2};
leave_only(_Args, Value, _Opts, _InData) ->
    {ok, Value}.

default([Default], _Value, Opts, InData) ->
    default(Default, _Value, Opts, InData);
default(Default, <<>>, _Opts, _InData) ->
    {ok, Default};
default(Default, _Value, _Opts, _InData) ->
    {ok, Default}.

%% internal
proplist(Value) ->
    proplist(Value, Value).

proplist([{_, _}|T], Value) ->
    proplist(T, Value);
proplist([], Value) ->
    {ok, Value};
proplist([_|_], _Value) ->
    {error, format_error}.

to_binary(Value) when is_number(Value) ->
    number_to_binary(Value);
to_binary(Value) when is_binary(Value) ->
    Value.

number_to_binary(Value) when is_integer(Value) ->
    integer_to_binary(Value);
number_to_binary(Value) when is_float(Value) ->
    oliver_float:to_binary(Value).

binary_to_number(Value) ->
    try erlang:binary_to_integer(Value)
    catch
        error:badarg -> erlang:binary_to_float(Value)
    end.

convert(FromTo, Value, Err) ->
    try erlang:FromTo(Value) of
        Value2 -> {ok, Value2}
    catch
        error:badarg -> Err
    end.
