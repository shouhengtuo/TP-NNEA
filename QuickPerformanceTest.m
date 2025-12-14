function QuickPerformanceTest()
% QuickPerformanceTest - Quick test of TP-NNEA with simulated data
% No dataset required for basic functionality testing
%
% This implementation is part of the research paper:
% "Integrating Cognitive Diagnosis and Multi-Objective Optimization for
% Personalized Exercise Recommendation: A Two-Stage Approach Based on
% Neural Network Dimensionality Reduction"
%
% Authors: Shouheng Tuo, Yong Zhao
% Journal: Computer Education (Under Review)
%
% Usage:
%   >> QuickPerformanceTest
%
% Outputs:
%   - Console performance metrics
%   - Quick_Performance_Test.png

    fprintf('=== TP-NNEA Quick Performance Test ===\n');
    fprintf('Testing with simulated data (no dataset required)\n\n');
    
    % Test configuration
    testConfigs = [
        struct('name', 'Small', 'N', 50, 'maxgen', 200, 'D', 100);
        struct('name', 'Medium', 'N', 100, 'maxgen', 400, 'D', 500);
        struct('name', 'Large', 'N', 200, 'maxgen', 600, 'D', 1000);
    ];
    
    % Generate simulated data
    fprintf('Generating simulated student and exercise data...\n');
    numStudents = 10;
    numExercises = 1000;
    numConcepts = 50;
    
    % Student knowledge states (random)
    student_emb = rand(numStudents, numConcepts);
    
    % Exercise difficulties
    k_difficulty = rand(numExercises, 5);
    
    % Q-matrix (exercise-concept mapping)
    Q_matrix = rand(numExercises, numConcepts) > 0.7;
    
    % Exercise logs (random history)
    exercise_log = rand(numStudents, numExercises) > 0.8;
    
    % Knowledge logs
    knowledge_log = rand(numStudents, numConcepts);
    
    % Predictions (simulated)
    predition = rand(numStudents, numExercises);
    
    % Store in Global for algorithm access
    Global.userData.student_emb = student_emb;
    Global.userData.k_difficulty = k_difficulty;
    Global.userData.Q_matrix = Q_matrix;
    Global.userData.exercise_log = exercise_log;
    Global.userData.knowledge_log = knowledge_log;
    Global.userData.predition = predition;
    Global.userData.e_diff = mean(k_difficulty, 2);
    
    fprintf('Data generated: %d students, %d exercises, %d concepts\n\n', ...
        numStudents, numExercises, numConcepts);
    
    % Run tests
    allResults = [];
    
    for c = 1:length(testConfigs)
        config = testConfigs(c);
        fprintf('--- Testing %s Scale (N=%d, gen=%d, D=%d) ---\n', ...
            config.name, config.N, config.maxgen, config.D);
        
        % Set global parameters
        Global.N = config.N;
        Global.maxgen = config.maxgen;
        Global.M = 3;
        Global.D = config.D;
        Global.lower = zeros(1, Global.D);
        Global.upper = ones(1, Global.D);
        Global.encoding = 'binary';
        
        % Test multiple students
        configResults = [];
        for s = 1:min(3, numStudents)  % Test up to 3 students
            fprintf('  Student %d/%d... ', s, min(3, numStudents));
            
            % Set student data
            Global.stuId = s;
            Global.stu_state = student_emb(s, :);
            
            % Run algorithm
            tic;
            try
                DyN_MOEA(Global);
                runtime = toc;
                
                % Collect simplified results
                fprintf('Done (%.2fs)\n', runtime);
                configResults = [configResults; runtime];
            catch ME
                fprintf('Error: %s\n', ME.message);
                configResults = [configResults; NaN];
            end
        end
        
        % Store configuration results
        result = struct();
        result.configName = config.name;
        result.avgRuntime = mean(configResults);
        result.stdRuntime = std(configResults);
        result.successRate = sum(~isnan(configResults)) / length(configResults);
        
        allResults = [allResults; result];
    end
    
    % Generate summary
    fprintf('\n=== Performance Summary ===\n');
    if ~isempty(allResults)
        fprintf('%-10s %-12s %-12s %-12s\n', 'Scale', 'Avg Runtime', 'Std Runtime', 'Success Rate');
        for i = 1:length(allResults)
            fprintf('%-10s %-12.4f %-12.4f %-12.1f%%\n', ...
                allResults(i).configName, ...
                allResults(i).avgRuntime, ...
                allResults(i).stdRuntime, ...
                allResults(i).successRate * 100);
        end
        
        % Visualization
        figure('Position', [100, 100, 800, 600]);
        
        % Runtime comparison
        subplot(1, 2, 1);
        configNames = {allResults.configName};
        avgRuntimes = [allResults.avgRuntime];
        bar(avgRuntimes);
        xlabel('Test Configuration');
        ylabel('Average Runtime (seconds)');
        title('Runtime Comparison');
        set(gca, 'XTickLabel', configNames);
        
        % Success rate
        subplot(1, 2, 2);
        successRates = [allResults.successRate] * 100;
        bar(successRates);
        xlabel('Test Configuration');
        ylabel('Success Rate (%)');
        title('Algorithm Success Rate');
        set(gca, 'XTickLabel', configNames);
        ylim([0, 100]);
        
        sgtitle('TP-NNEA Quick Performance Test');
        
        saveas(gcf, 'Quick_Performance_Test.png');
        fprintf('\nVisualization saved to Quick_Performance_Test.png\n');
    end
    
    fprintf('\n=== Quick Test Complete ===\n');
    fprintf('For full evaluation with real datasets, run: AlgorithmPerformanceTest\n');
end