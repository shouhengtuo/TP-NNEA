%% Multi-objective optimization: Calculate the fitness of each solution
function Fitness = CalFitness1(PopObj,PopCon)
% Calculate the fitness of each solution

%------------------------------- Copyright --------------------------------
% Copyright (c) 2018-2019 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    % Get population size
    N = size(PopObj,1);
    % Calculate the constraint violation degree for each solution, first calculate the sum of constraint values for each solution in PopCon, take the minimum value as 0, then sum all constraint values in each solution, get a one-dimensional vector CV, where each element corresponds to the constraint violation degree of that solution.
    CV = sum(max(0,PopCon),2);

    %% Compare each pair in the population to determine if one solution dominates another
    % Dominance relationship matrix
    Dominate = false(N);
    for i = 1 : N-1
        for j = i+1 : N
                if CV(i) < CV(j)
                    % If constraint violation degree of i < constraint violation degree of j, then i dominates j
                    Dominate(i,j) = true;
                elseif CV(i) > CV(j)
                    Dominate(j,i) = true;
                % If constraint violation degrees are equal, need to compare through objective function values to determine dominance relationship
                else
                    k = any(PopObj(i,:)<PopObj(j,:)) - any(PopObj(i,:)>PopObj(j,:));
                    % If objective function values of i are all less than objective function values of j, then i dominates j
                    if k == 1
                        Dominate(i,j) = true;
                    % If objective function values of i are all greater than objective function values of j, then j dominates i
                    elseif k == -1
                        Dominate(j,i) = true;
                    end
                end
        end
    end
    
    %% Calculate how many solutions each solution dominates, and how many solutions dominate solution i
    S = sum(Dominate,2);
    
    %% Used to store the dominance number of each solution R(i)
    R = zeros(1,N);
    for i = 1 : N
        R(i) = sum(S(Dominate(:,i)));
    end
    
    %% Calculate D(i)
    % Calculate the Euclidean distance between each pair of solutions to get the distance matrix
    Distance = pdist2(PopObj,PopObj);
    % Set diagonal elements of the distance matrix to infinity
    Distance(logical(eye(length(Distance)))) = inf;
    % Sort each row of the distance matrix to get the distance from each solution to other solutions, to calculate D(i)
    Distance = sort(Distance,2);
    % Calculate the crowding degree D(i) of each solution, the distance from the solution to the k-th nearest solution in the objective space
    D = 1./(Distance(:,floor(sqrt(N)))+2);

    %% Calculate the fitness of each solution, the sum of dominance number R(i) and crowding degree D(i), the higher the fitness, the better the solution
    Fitness = R + D';
end