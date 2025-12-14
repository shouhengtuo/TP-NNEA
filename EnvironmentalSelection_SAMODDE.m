function [Population, Fitness] = EnvironmentalSelection_SAMODDE(Population, N)
% SA-MODDE 环境选择（改进版）
% 逐前沿装箱；最后一层超额时用“目标归一化 + 拥挤距离 + Q-矩阵覆盖熵”的综合分数截断
%
% 综合分（越小越好）:
%   score = w_obj * mean(norm_obj,2) + w_cd * (1 - CD_norm) + w_ent * (1 - H_norm)
% 其中：
%   - norm_obj  : 目标逐列[min,max]归一化
%   - CD_norm   : 拥挤距离归一化到[0,1]，CD越大→(1-CD_norm)越小→更优
%   - H_norm    : 覆盖熵归一化到[0,1]，熵越大→(1-H_norm)越小→更优

    % ---------------- 可调权重 ----------------
    w_obj = 0.20;   % 目标性能权重（越小越好）
    w_cd  = 0.50;   % 拥挤距离权重（更稀疏更好）
    w_ent = 0.30;   % 知识点覆盖熵权重（更分散更好）

    % ---------------- 1) 去重（按目标） ----------------
    [~, uni]   = unique(Population.objs, 'rows');
    Population = Population(uni);
    N          = min(N, length(Population));

    if isempty(Population)
        return;
    end

    % ---------------- 2) 约束支配非支配排序 ----------------
    [FrontNo, MaxFNo] = NDSort(Population.objs, Population.cons, N);

    % ---------------- 3) 逐前沿装箱，最后一层截断 ----------------
    Next = false(1, length(Population));
    sel  = 0;

    % 获取 Q（建议在 INDIVIDUAL 构造时保存 Qs = Q_matrix）
    Q = [];
    % 一些项目把附加信息放在 addinfo 里
    if isfield(Population(1), 'addinfo')
        try
            if isfield(Population(1).addinfo, 'Qs')
                Q = Population(1).addinfo.Qs;
            end
        catch
        end
    end
    % 或直接作为个体字段 Qs
    if isempty(Q)
        try
            if isfield(Population(1), 'Qs')
                Q = Population(1).Qs;
            end
        catch
        end
    end
    K = 0;
    if ~isempty(Q)
        K = size(Q,2);
    end

    for f = 1:MaxFNo
        idx = find(FrontNo == f);

        % 剩余容量足够：整层收下
        if sel + numel(idx) <= N
            Next(idx) = true;
            sel       = sel + numel(idx);
            continue;
        end

        % ---------- 最后一层：混合截断 ----------
        Kneed = N - sel;                 % 还需要选多少个
        if Kneed <= 0
            break;
        end

        % 该前沿的目标矩阵：(#F) x M
        objsF = Population(idx).objs;

        % 目标逐列归一化 [0,1]
        minv = min(objsF, [], 1);
        maxv = max(objsF, [], 1);
        rngv = maxv - minv;   rngv(rngv == 0) = 1;
        norm_obj = (objsF - minv) ./ rngv;    % (#F) x M

        % ---- 拥挤距离（只在该层内），含健壮处理 ----
        FrontNo_F = ones(size(norm_obj,1),1);       % 该层视为同一前沿
        CD = CrowdingDistance(norm_obj, FrontNo_F); % 列向量

        % A) 如果全为 Inf（前沿解过少等情况）
        if all(isinf(CD))
            CD(:) = 0;                       % 也可设为1，看“是否奖励边界点”的设计
        else
            % B) 既有 Inf 又有有限值：把 Inf 置为有限最大值+1
            finiteCD = CD(~isinf(CD));
            if isempty(finiteCD)
                CD(:) = 0;                   % 兜底
            else
                maxFinite     = max(finiteCD);
                CD(isinf(CD)) = maxFinite + 1;
            end
        end

        % 归一化到[0,1]
        minCD = min(CD);
        maxCD = max(CD);
        if maxCD == minCD
            CD_norm = zeros(size(CD));
        else
            CD_norm = (CD - minCD) ./ (maxCD - minCD);
        end

        % ---- 覆盖熵（需要 Q）：decs * Q → 概率 → 熵；归一化到[0,1] ----
        entropy = zeros(numel(idx), 1);
        if ~isempty(Q) && K > 1
            for t = 1:numel(idx)
                dec_t = Population(idx(t)).decs;   % 1 x D（二值）
                cover = dec_t * Q;                  % 1 x K
                s = sum(cover);
                if s <= 0
                    H = 0;                          % 无覆盖 → 熵=0
                else
                    p = cover / (s + eps);          % 概率
                    H = -sum(p .* log2(p + eps));   % 信息熵
                end
                % 熵归一化（最大为 log2(K)）
                entropy(t) = H / (log2(K + (K==0)) + eps);
            end
        else
            entropy(:) = 0;                         % 无 Q 时退化为0
        end
        H_norm = max(0, min(1, entropy));           % 裁剪到[0,1]

        % ---- 目标性能指标：归一化目标的均值（也可换切比雪夫/加权和）----
        perf = mean(norm_obj, 2);                   % 越小越好

        % ---- 综合分（越小越好）----
        score = w_obj * perf + w_cd * (1 - CD_norm) + w_ent * (1 - H_norm);

        % 选择综合分最小的 Kneed 个
        [~, ord] = sort(score, 'ascend');
        pick = idx(ord(1:Kneed));
        Next(pick) = true;
        break;
    end

    % ---------------- 4) 返回 ----------------
    Population = Population(Next);

    % 计算 Fitness 值并返回
    Fitness = CalFitness1(Population.objs, Population.cons); % 计算适应度
end
