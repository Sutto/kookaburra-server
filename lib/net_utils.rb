module NetUtils
    def carp(arg)
        if arg.kind_of?(Exception)
          Kookaburra.logger.debug_exception arg
        else
          Kookaburra.logger.debug arg
        end
  end
end
