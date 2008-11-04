module NetUtils
    def carp(arg)
        if $verbose
            case  true
            when arg.kind_of?(Exception)
                puts "Error:" + arg.message 
                puts "#{self.class.to_s}: " + arg.message 
                puts arg.backtrace.collect{|s| "#{self.class.to_s.downcase}:" + s}.join("\n")
            else
                puts "#{self.class.to_s}: " + arg
            end
        end
    end
end
