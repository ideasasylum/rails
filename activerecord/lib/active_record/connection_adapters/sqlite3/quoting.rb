# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLite3
      module Quoting # :nodoc:
        def quote(value)
          case value
          when String
            if value.encoding == Encoding::BINARY
              quoted_binary(value)
            else
              "'#{quote_string(value.to_s)}'"
            end
          else
            super
          end
        end

        def quote_string(s)
          ::SQLite3::Database.quote(s)
        end

        def quote_table_name_for_assignment(table, attr)
          quote_column_name(attr)
        end

        def quote_table_name(name)
          self.class.quoted_table_names[name] ||= super.gsub(".", "\".\"").freeze
        end

        def quote_column_name(name)
          self.class.quoted_column_names[name] ||= %Q("#{super.gsub('"', '""')}")
        end

        def quoted_time(value)
          value = value.change(year: 2000, month: 1, day: 1)
          quoted_date(value).sub(/\A\d\d\d\d-\d\d-\d\d /, "2000-01-01 ")
        end

        def quoted_binary(value)
          if value.is_a? String
            "x'#{value.unpack1("H*")}'"
          else
            "x'#{value.hex}'"
          end
        end

        def quoted_true
          "1"
        end

        def unquoted_true
          1
        end

        def quoted_false
          "0"
        end

        def unquoted_false
          0
        end

        def quote_default_expression(value, column) # :nodoc:
          if value.is_a?(Proc)
            value = value.call
            if value.match?(/\A\w+\(.*\)\z/)
              "(#{value})"
            else
              value
            end
          else
            super
          end
        end

        def type_cast(value) # :nodoc:
          case value
          when BigDecimal
            value.to_f
          else
            super
          end
        end

        def column_name_matcher
          COLUMN_NAME
        end

        def column_name_with_order_matcher
          COLUMN_NAME_WITH_ORDER
        end

        COLUMN_NAME = /
          \A
          (
            (?:
              # "table_name"."column_name" | function(one or no argument)
              ((?:\w+\.|"\w+"\.)?(?:\w+|"\w+") | \w+\((?:|\g<2>)\))
            )
            (?:(?:\s+AS)?\s+(?:\w+|"\w+"))?
          )
          (?:\s*,\s*\g<1>)*
          \z
        /ix

        COLUMN_NAME_WITH_ORDER = /
          \A
          (
            (?:
              # "table_name"."column_name" | function(one or no argument)
              ((?:\w+\.|"\w+"\.)?(?:\w+|"\w+") | \w+\((?:|\g<2>)\))
            )
            (?:\s+COLLATE\s+(?:\w+|"\w+"))?
            (?:\s+ASC|\s+DESC)?
          )
          (?:\s*,\s*\g<1>)*
          \z
        /ix

        private_constant :COLUMN_NAME, :COLUMN_NAME_WITH_ORDER
      end
    end
  end
end
