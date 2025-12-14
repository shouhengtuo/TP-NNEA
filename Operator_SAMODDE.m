function [OffWeight, OffF, OffCr, stratIdx] = Operator_SAMODDE(PopWeight, F, CR, strategyProb, Population, N, Dim)
% Operator_SAMODDE - SA-MODDE差分演化操作算子（支持多策略 + 自适应控制参数）
% 输入：
%   PopWeight     - 当前种群权重矩阵 (N x Dim)
%   F, CR         - 每个个体的缩放因子和交叉率向量 (N x 1)
%   strategyProb  - 四种变异策略的概率 (4 x 1)
%   Population    - 种群对象，用于查找全局最优个体
%   N, Dim        - 个体数和维度数
% 输出：
%   OffWeight     - 子代个体权重
%   OffF, OffCR   - 子代对应控制参数
%   stratIdx      - 每个个体使用的变异策略编号

    M = size(PopWeight, 1);  % 实际采样个体数
    OffWeight = zeros(N, Dim);
    OffF = F; OffCr = CR; stratIdx = zeros(N, 1);

    for i = 1:N
        % 策略选择（轮盘赌）
        r = rand(); cs = cumsum(strategyProb);
        strat = find(r <= cs, 1);
        stratIdx(i) = strat;

        % 自适应 F 和 CR
        if rand < 0.1, OffF(i) = 0.1 + 0.9 * rand(); end
        if rand < 0.1, OffCr(i) = rand(); end

        % 随机选择索引（从 M 个体中采样）
        idx = randperm(M);
        if length(idx) < 5
            idx(end+1:5) = randi(M, 1, 5 - length(idx));  % 兜底补足长度
        end
        r1 = idx(1); r2 = idx(2); r3 = idx(3);

        % 多策略差分变异
        if strat == 1  % rand/1
            vi = PopWeight(r1,:) + OffF(i) * (PopWeight(r2,:) - PopWeight(r3,:));
        elseif strat == 2  % current-to-best/1
            [~, bestIdx] = min([Population.obj]);
            bestIdx = min(bestIdx, M);  % 防越界
            vi = PopWeight(i,:) + OffF(i)*(PopWeight(bestIdx,:) - PopWeight(i,:)) + OffF(i)*(PopWeight(r1,:) - PopWeight(r2,:));
        elseif strat == 3  % best/2
            [~, bestIdx] = min([Population.obj]);
            r4 = idx(4); r5 = idx(5);
            bestIdx = min(bestIdx, M);  % 防越界
            vi = PopWeight(bestIdx,:) + OffF(i)*(PopWeight(r1,:) - PopWeight(r2,:)) + OffF(i)*(PopWeight(r4,:) - PopWeight(r5,:));
        else  % rand-to-best/2
            [~, bestIdx] = min([Population.obj]);
            bestIdx = min(bestIdx, M);
            vi = PopWeight(r1,:) + rand()*(PopWeight(bestIdx,:) - PopWeight(r1,:)) + OffF(i)*(PopWeight(r2,:) - PopWeight(r3,:));
        end

        % 交叉（binomial crossover）
        ui = PopWeight(min(i, M), :);  % 避免越界访问
        jrand = randi(Dim);
        for j = 1:Dim
            if rand < OffCr(i) || j == jrand
                ui(j) = vi(j);
            end
        end
        
        % 边界修复（确保网络权重在 [-1, 1]）
        ui = max(min(ui, 1), -1);
        OffWeight(i,:) = ui;
    end
end
