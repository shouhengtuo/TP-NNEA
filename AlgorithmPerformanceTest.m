function AlgorithmPerformanceTest()
% AlgorithmPerformanceTest - Performance evaluation for TP-NNEA algorithm
% Tests algorithm on real datasets and generates comprehensive analysis
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
%   >> AlgorithmPerformanceTest
%
% Outputs:
%   - Console performance metrics
%   - TP_NNEA_Performance_Analysis.png
%   - TP_NNEA_Results.csv
%   - TP_NNEA_Summary.mat

    fprintf('=== TP-NNEA Algorithm Performance Test ===\n');
    
    % Dataset path configuration
    dataPath = "DyN-MOEA/Exerciese Recommendation/dataSet1.mat";
    
    if ~exist(dataPath, 'file')
        error('Dataset file not found: %s', dataPath);
    end
    
    fprintf('Loading dataset: %s\n', dataPath);
    
    % Test configuration
    testStudents = [1, 5, 10, 15, 20];  % Test student IDs
    numExercises = [50, 100];              % Exercise counts to test
    numRuns = 5;                            % Runs per configuration
    
    fprintf('Testing %d students with %d exercise configurations\n', ...
        length(testStudents), length(numExercises));
    
    % Initialize results storage
    allResults = [];
    
    % Run tests
    for s = 1:length(testStudents)
        stuId = testStudents(s);
        for e = 1:length(numExercises)
            num = numExercises(e);
            
            fprintf('\n--- Testing Student %d, %d Exercises ---\n', stuId, num);
            
            % Multiple runs for statistical significance
            runResults = [];
            for r = 1:numRuns
                fprintf('Run %d/%d... ', r, numRuns);
                
                % Set up global parameters
                Global.N = 100;
                Global.maxgen = 400;  % Reduced for faster testing
                Global.M = 3;
                Global.D = 17746;  % ASSISTments dataset size
                Global.lower = zeros(1, Global.D);
                Global.upper = ones(1, Global.D);
                Global.encoding = 'binary';
                
                % Load student data
                dataSet = load(dataPath);
                str = {'student_emb','k_difficulty','Q_matrix','exercise_log','knowledge_log','predition'};
                stu_state = dataSet.dataSet11.(str{1})(stuId,:);
                exer_difficulty = dataSet.dataSet11.(str{2});
                Q_matrix = double(dataSet.dataSet11.(str{3}));
                exer_log = double(dataSet.dataSet11.(str{4})(stuId,:));
                knowledge_log = double(dataSet.dataSet11.(str{5})(stuId,:));
                predition = dataSet.dataSet11.(str{6})(stuId,:);
                
                % Store in Global for algorithm access
                Global.userData.stu_state = stu_state;
                Global.userData.exer_diff = exer_difficulty;
                Global.userData.Q_matrix = Q_matrix;
                Global.userData.exer_log = exer_log;
                Global.userData.knowledge_log = knowledge_log;
                Global.userData.predition = predition;
                
                % Run algorithm
                tic;
                try
                    DyN_MOEA(Global);
                    runtime = toc;
                    
                    % Collect results (simplified for this test)
                    runResults = [runResults; runtime];
                    fprintf('Done (%.2fs)\n', runtime);
                catch ME
                    fprintf('Error: %s\n', ME.message);
                    runResults = [runResults; NaN];
                end
            end
            
            % Store configuration results
            configResults = struct();
            configResults.studentId = stuId;
            configResults.exerciseCount = num;
            configResults.runtimes = runResults;
            configResults.avgRuntime = mean(runResults);
            configResults.stdRuntime = std(runResults);
            
            allResults = [allResults; configResults];
        end
    end
    
    % Generate summary
    fprintf('\n=== Performance Summary ===\n');
    if ~isempty(allResults)
        avgRuntimes = [allResults.avgRuntime];
        fprintf('Average runtime: %.2f ± %.2f seconds\n', ...
            mean(avgRuntimes), std(avgRuntimes));
        
        % Save results
        save('TP_NNEA_Summary.mat', 'allResults');
        
        % Generate CSV report
        csvData = [];
        for i = 1:length(allResults)
            csvData = [csvData; ...
                allResults(i).studentId, ...
                allResults(i).exerciseCount, ...
                allResults(i).avgRuntime, ...
                allResults(i).stdRuntime];
        end
        
        % Write CSV
        fid = fopen('TP_NNEA_Results.csv', 'w');
        fprintf(fid, 'StudentId,ExerciseCount,AvgRuntime,StdRuntime\n');
        for i = 1:size(csvData, 1)
            fprintf(fid, '%d,%d,%.4f,%.4f\n', csvData(i,:));
        end
        fclose(fid);
        
        fprintf('Results saved to TP_NNEA_Results.csv and TP_NNEA_Summary.mat\n');
        
        % Simple visualization
        figure('Position', [100, 100, 800, 600]);
        students = [allResults.studentId];
        exercises = [allResults.exerciseCount];
        runtimes = [allResults.avgRuntime];
        
        % Group by exercise count
        uniqueExercises = unique(exercises);
        for e = 1:length(uniqueExercises)
            mask = exercises == uniqueExercises(e);
            scatter(students(mask), runtimes(mask), 50, 'filled', ...
                'DisplayName', sprintf('%d exercises', uniqueExercises(e)));
            hold on;
        end
        
        xlabel('Student ID');
        ylabel('Average Runtime (seconds)');
        title('TP-NNEA Performance: Runtime vs Exercise Count');
        legend('Location', 'best');
        grid on;
        
        saveas(gcf, 'TP_NNEA_Performance_Analysis.png');
        fprintf('Visualization saved to TP_NNEA_Performance_Analysis.png\n');
    end
    
    fprintf('\n=== Test Complete ===\n');
end