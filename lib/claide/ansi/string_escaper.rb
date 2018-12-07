module CLAide
  class ANSI
    # Provides support to wrap strings in ANSI sequences according to the
    # `ANSI.disabled` setting.
    #
    class StringEscaper < String
      # @param  [String] string The string to wrap.
      #
      def initialize(string)
        super
      end

      # @return [StringEscaper] Wraps a string in the given ANSI sequences,
      #         taking care of handling existing sequences for the same
      #         family of attributes (i.e. attributes terminated by the
      #         same sequence).
      #包装成   最开始是oepn , 最后是close.   中间的close被替换
      def wrap_in_ansi_sequence(open, close)
        if ANSI.disabled
          self
        else
          # 替换
          gsub!(close, open)
          insert(0, open).insert(-1, close)
        end
      end

      # @return [StringEscaper]
      #
      # @param  [Array<Symbol>] keys
      #         One or more keys corresponding to ANSI codes to apply to the
      #         string.
      #
      def apply(*keys)
        # .flatten  返回一个扁平化的一维数组
        keys.flatten.each do |key|
          # 调用key方法
          send(key)
        end
        self
      end

      ANSI::COLORS.each_key do |key|
        # Defines a method returns a copy of the receiver wrapped in an ANSI
        # sequence for each foreground color (e.g. #blue).
        #
        # The methods handle nesting of ANSI sequences.
        #
        # 定义方法名为 key的方法
        define_method key do
          # 方法体的内容
          open = Graphics.foreground_color(key)
          close = ANSI::DEFAULT_FOREGROUND_COLOR
          wrap_in_ansi_sequence(open, close)
        end

        # Defines a method returns a copy of the receiver wrapped in an ANSI
        # sequence for each background color (e.g. #on_blue).
        #
        # The methods handle nesting of ANSI sequences.
        #
        define_method "on_#{key}" do
          open = Graphics.background_color(key)
          close = ANSI::DEFAULT_BACKGROUND_COLOR
          wrap_in_ansi_sequence(open, close)
        end
      end

      # 简直是魔法


      ANSI::TEXT_ATTRIBUTES.each_key do |key|
        # Defines a method returns a copy of the receiver wrapped in an ANSI
        # sequence for each text attribute (e.g. #bold).
        #
        # The methods handle nesting of ANSI sequences.
        #
        define_method key do
          # 修改控制台颜色效果
          open = Graphics.text_attribute(key)
          close_code = TEXT_DISABLE_ATTRIBUTES[key]
          close = Graphics.graphics_mode(close_code)
          wrap_in_ansi_sequence(open, close)
        end
      end
    end
  end
end
