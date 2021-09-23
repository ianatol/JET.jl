include("setup.jl")

@testset "JET.jl" begin
    @testset "abstractinterpret" begin
        @testset "inferenceerrorreport.jl" begin
            include("abstractinterpret/test_inferenceerrorreport.jl")
        end

        @testset "typeinfer.jl" begin
            include("abstractinterpret/test_typeinfer.jl")
        end
    end

    @testset "toplevel" begin
        @testset "virtualprocess.jl" begin
            include("toplevel/test_virtualprocess.jl")
        end
    end

    @testset "ui" begin
        # tests with Windows-paths is just an hell
        @static Sys.iswindows() || @testset "print.jl" begin
            include("ui/test_print.jl")
        end

        @testset "vscode.jl" begin
            include("ui/test_vscode.jl")
        end
    end

    @testset "misc" begin
        include("test_misc.jl")
    end

    @testset "Test.jl integration" begin
        include("test_Test.jl")
    end

    @testset "JETInterface" begin
        include("test_JETInterface.jl")
    end

    @testset "analyzers" begin
        @testset "JETAnalyzer" begin
            include("analyzers/test_jetanalyzer.jl")
        end

        @testset "OptAnalyzer" begin
            include("analyzers/test_optanalyzer.jl")
        end
    end

    # run simple performance benchmark
    # and also run OptAnalyzer on JET
    @testset "performance" begin
        include("performance.jl")
    end

    @testset "self check !!!" begin
        target_modules = (JET,)
        JETAnalyzerT   = typeof(JET.JETAnalyzer())
        OptAnalyzerT   = typeof(JET.OptAnalyzer())
        InferenceState = Core.Compiler.InferenceState

        # error analysis
        # ==============

        # JETAnalyzer
        test_call(JET.analyze_frame!, (JETAnalyzerT, InferenceState);
                  target_modules)
        # OptAnalyzer
        test_call(JET.analyze_frame!, (OptAnalyzerT, InferenceState);
                  target_modules)
        # top-level
        test_call(JET.virtual_process, (String, String, JETAnalyzerT, JET.ToplevelConfig);
                  target_modules)
        # entries
        test_call(JET.report_file, (String,);
                  target_modules)
        test_call(JET.report_package, (Union{String,Module,Nothing},);
                  target_modules)

        # optimization analysis
        # =====================

        function function_filter(@nospecialize ft)
            if ft === typeof(JET.widenconst) ||
               ft === typeof(JET.print) ||
               ft === typeof(Base.CoreLogging.handle_message) ||
               ft == Type{<:JET.InferenceErrorReport} # the constructor used in `restore_cached_report` is very dynamic
                return false
            end
            return true
        end
        # JETAnalyzer
        test_opt(JET.analyze_frame!, (JETAnalyzerT, InferenceState);
                 target_modules,
                 function_filter)
        # OptAnalyzer
        test_opt(JET.analyze_frame!, (OptAnalyzerT, InferenceState);
                 target_modules,
                 function_filter)
    end
end
