function TP_NNEA(Global)
% <algorithm> <T>
% 学生习题推荐的两阶段多目标进化：阶段一（SA-MODDE 权重进化）+ 阶段二（熵引导+档案g引导的融合翻转）
% stuId ---  1 --- 学生ID
% num   --- 100 --- 推荐题目数

    %% ------------------------- 数据与特征 -------------------------
    [stuId,num] = Global.ParameterSet(1,50);
    str  = {'student_emb','k_difficulty','Q_matrix','exercise_log','knowledge_log','predition','e_difficulty'};
    
    dataSet2     = load("E:\PlatEMO-2.0.0\PlatEMO-2.0.0\PlatEMO\Problems\Exerciese Recommendation\dataSet1.mat");
    stu_state  = dataSet2.dataSet11.(str{1})(stuId,:);
    exer_diff  = dataSet2.dataSet11.(str{2});
    Q_matrix   = double(dataSet2.dataSet11.(str{3}));     % D x K
    exer_log   = double(dataSet2.dataSet11.(str{4})(stuId,:));
    knowledge_log = double(dataSet2.dataSet11.(str{5})(stuId,:));
    predition  = dataSet2.dataSet11.(str{6})(stuId,:);
    e_diff     = mean(exer_diff, 2);
    
    
%     dataSet2     = load("E:\PlatEMO-2.0.0\PlatEMO-2.0.0\PlatEMO\Problems\Exerciese Recommendation\dataSet2.mat");
%     student_emb2 = load("E:\PlatEMO-2.0.0\PlatEMO-2.0.0\PlatEMO\Algorithms\RCEA\student_emb2.mat");
%     stu_state  = dataSet2.(str{1})(stuId,:);
%     exer_diff  = dataSet2.(str{2});
%     Q_matrix   = double(dataSet2.(str{3}));
%     exer_log   = double(dataSet2.(str{4})(stuId,:));
%     knowledge_log = double(dataSet2.(str{5})(stuId,:));
%     predition  = dataSet2.(str{6})(stuId,:);
%     e_diff     = dataSet2.(str{7});
    

    % 过滤题目索引
    indexc1 = find(exer_log==1);
    indexc2 = find(predition<0.01 | predition>0.99);
    decision = [setdiff(indexc1,intersect(indexc1,indexc2)) indexc2];
    Decision = setdiff(1:Global.D, decision);   % 可推荐题集合

%     % 二值化预测值（可按需调阈）
%     predition = double(predition>=0.65);
%     predition = predition(1,Decision);

%     % 统计每题中学生最薄弱概念（仅分析用）
%     group = zeros(1,length(Decision));
%     for i=1:length(Decision)
%         idx = find(Q_matrix(Decision(i),:)==1);
%         [~,z] = min(stu_state(idx));
%         group(i)=idx(z);
%     end
%     Q = Q_matrix(Decision,:);

    % 神经网络输入（学生状态 + 题-概念 + 难度）
    Instance = zeros(size(Q_matrix,1), 2*size(Q_matrix,2)+1);
    for i=1:size(Q_matrix,1)
        Instance(i,:) = [stu_state, Q_matrix(i,:), e_diff(i)];
    end
    structure = [size(Instance,2), 25, 50, 1];
    s_list    = ones((numel(structure)-1)*2,2)*-1;
    Dim = 0;
    for i = 1:numel(structure)-1
        s_list(2*i-1,1) = structure(i);
        s_list(2*i-1,2) = structure(i+1);
        s_list(2*i  ,1) = structure(i+1);
        Dim = Dim + structure(i)*structure(i+1) + structure(i+1);
    end

    % 搜索边界（网络权重）
    lower_network = -1*ones(1,Dim);  upper_network = 1*ones(1,Dim);

    %% ------------------------- 一阶段控制参数 -------------------------
    % DE 控制参数
    PopWeight = zeros(Global.N,Dim);
    F  = 0.1 + 0.9*rand(Global.N,1);
    Cr = rand(Global.N,1);
    strategyProb    = rand(4,1); strategyProb = strategyProb/sum(strategyProb);
    strategySuccess = zeros(4,1);

    for i=1:Dim
        PopWeight(:,i) = lower_network(i) + (upper_network(i)-lower_network(i))*rand(Global.N,1);
    end

    % 初始种群（由权重前向）
    Output = FCNForward(PopWeight, Instance, s_list);
    for i=1:size(Output,1)
        [~,idx] = sort(Output(i,:),'descend');
        Output(i,idx(1:num))=1; Output(i,idx(num+1:end))=0;
    end
    Population = INDIVIDUAL(Output, PopWeight, F, Cr, Q_matrix);
    Fitness = CalFitness1(Population.objs, Population.cons); % 计算适应度

    % delta 动态调度
    if ~exist('delta','var'),           delta=0.60; end
    if ~exist('min_phase_ratio','var'), min_phase_ratio=0.40; end
    if ~exist('max_phase_ratio','var'), max_phase_ratio=0.85; end
    if ~exist('delta_step','var'),      delta_step=0.05; end
    if ~exist('fc_hist','var'),         fc_hist=[]; end
    Wm=11; med_low=2e-3; med_high=8e-3;

    prev_objs = [];
    pareto_objs_matrix = []; pareto_gen_counter=0;

    %% ------------------------- 二阶段融合参数 -------------------------
    % 档案（存概念计数目标 g）
    A = struct('g',{},'dec',{},'objs',{});
    Amax = 60;
    % 熵变异强度
    topK_entropy = 5;    % 从熵值高的 topK 中挑位点做翻转
    % 两路后代的比例（0~1）：mix_ratio * guided + (1-mix_ratio) * entropy
    mix_ratio   = 0.6;   % 推荐 0.5~0.7，越大越靠拢 g 模板
    K = size(Q_matrix,2);

    %% --------------------------- 主循环 ---------------------------
    while Global.NotTermination(Population)
        current_objs = Population.objs;
        % 适应度变化率
        if isempty(prev_objs)
            fitness_change_rate = Inf;
        else
            fitness_change_rate = sum(abs(current_objs(:)-prev_objs(:)))/numel(current_objs);
        end
        fprintf('第 %d 代适应度变化率: %.6f\n', Global.gen, fitness_change_rate);
        prev_objs = current_objs;

        % 中位数窗口调 delta
        fc_hist = [fc_hist, fitness_change_rate];
        if numel(fc_hist)>Wm, fc_hist = fc_hist(end-Wm+1:end); end
        if numel(fc_hist)>=Wm
            med_fc = median(fc_hist);
            fprintf('第 %d 代变化率中位数(窗口=%d): %.6f\n', Global.gen, Wm, med_fc);
            if med_fc<med_low
                delta = max(min_phase_ratio, delta - delta_step);
            elseif med_fc>med_high
                delta = min(max_phase_ratio, delta + delta_step);
            end
        end

        %% ========== 阶段一：SA-MODDE 进化网络权重 ==========
        if Global.gen <= Global.maxgen*delta
            MatingPool = TournamentSelection(2,Global.N,Fitness);
            PopWeight = Population(MatingPool).adds;
            [OffWeight, OffF, OffCr, stratIdx] = Operator_SAMODDE(PopWeight,F,Cr, strategyProb, Population(MatingPool), Global.N, Dim);
            Out = FCNForward(OffWeight, Instance, s_list);
            for i=1:size(Out,1)
                [~,idx] = sort(Out(i,:),'descend');
                Out(i,idx(1:num))=1; Out(i,idx(num+1:end))=0;
            end
            Offspring = INDIVIDUAL(Out, OffWeight, OffF, OffCr, Q_matrix);
            [Population,Fitness] = EnvironmentalSelection_SAMODDE([Population,Offspring], Global.N);

            % 策略胜率统计
            PopStr = string(num2str(round(Population.decs,6)));
            OffStr = string(num2str(round(Offspring.decs,6)));
            [isMatched,~] = ismember(OffStr, PopStr);
            for j=1:Global.N
                if isMatched(j), strategySuccess(stratIdx(j)) = strategySuccess(stratIdx(j))+1; end
            end
            tot = sum(strategySuccess);
            if tot>0, strategyProb = strategySuccess/tot; end
        end

        %% ========== 阶段二：融合“熵引导 + g 引导”的翻转 ==========
        if Global.gen > Global.maxgen*delta
            % 父代池：当前第一前沿
            FrontNo = NDSort(Population.objs, Population.cons, Global.N);
            PFIdx   = find(FrontNo==1);
            if isempty(PFIdx), PFIdx = 1:min(Global.N,numel(Population)); end
            ParetoP = Population(PFIdx);

            % 初始化/更新档案
            if isempty(A), A = seedArchiveFromFront(ParetoP, Q_matrix, Amax); end

            % 计算位置熵（基于当前全种群，衡量“容易出变化/不确定”的位点）
            entropy_vec = positionEntropy(Population.decs);

            % 两路后代规模
            nGuided = round(Global.N * mix_ratio);
            nEntrop = Global.N - nGuided;

            % —— g 引导的后代（定向成组修正）——
            OffDecs_g = zeros(nGuided, Global.D);
            for i=1:nGuided
                p   = ParetoP(randi(numel(ParetoP))).decs;
                a   = A(randi(numel(A)));         % 随机取一个模板
                g   = a.g;                        % 1×K 目标概念计数
                d_g = guidedFlipByConcept(p, g, Q_matrix,0.5);
                d_g = repairC1_num(d_g, num);
                OffDecs_g(i,:) = d_g;
            end

            % —— 熵引导的后代（轻量随机扰动）——
            OffDecs_e = zeros(nEntrop, Global.D);
            [~,rankPos] = sort(entropy_vec,'descend');
            hotSet = rankPos(1:min(topK_entropy, numel(rankPos)));
            for i=1:nEntrop
                p = ParetoP(randi(numel(ParetoP))).decs;
                d_e = entropyFlipOne(p, hotSet);
                d_e = repairC1_num(d_e, num);
                OffDecs_e(i,:) = d_e;
            end

            % 合并后代
            OffDecs = [OffDecs_g; OffDecs_e];
            Offspring = INDIVIDUAL(OffDecs, Population.adds, [], [], Q_matrix);

            % 环境选择 + 档案更新
            Population = EnvironmentalSelection_SAMODDE([Population,Offspring], Global.N);
            A = updateArchive(A, Population, Q_matrix, Amax);
        end

        % ------------------------- 可视化每100代精英个体目标值变化 -------------------------
        if mod(Global.gen, 100) == 0
            % 获取第一帕累托前沿个体
            FrontNo = NDSort(Population.objs, inf);  % 对种群进行非支配排序
            pareto_set = Population(FrontNo == 1);   % 第一帕累托前沿的个体

            % 获取目标函数值（目标1和目标3）
            pareto_objs = cat(1, pareto_set.obj);  % 获取所有精英个体的目标值

            % 获取目标1和目标3的值
            goal1 = pareto_objs(:, 1);  % 目标1的值
            goal3 = pareto_objs(:, 3);  % 目标3的值

            % 将目标1和目标3的值保存到矩阵中
            new_data = [goal1, goal3];  % 将目标1和目标3拼接成一个新的矩阵

            % 每隔100代保存一行
            pareto_gen_counter = pareto_gen_counter + 1;
            for i = 1:size(new_data, 1)
                pareto_objs_matrix(pareto_gen_counter, (i-1)*2+1:(i-1)*2+2) = new_data(i, :);
            end
        end

        % ------------------------- 绘制目标1和目标3的散点图 -------------------------
        if Global.gen == Global.maxgen
            figure;
            hold on;

            % 获取目标1和目标3的值
            goal1 = pareto_objs_matrix(:, 1:2:end);  % 目标1的值（奇数列）
            goal3 = pareto_objs_matrix(:, 2:2:end);  % 目标3的值（偶数列）

            % 获取代数（行数）
            num_generations = size(pareto_objs_matrix, 1);

            % 创建颜色映射，使用不同颜色表示每100代
            colors = jet(num_generations);  % jet 是一种颜色映射，生成不同颜色

            % 循环绘制每100代的精英个体
            for i = 1:num_generations
                % 绘制散点图
                scatter(goal3(i, :), goal1(i, :), 50, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
            end

            % 设置图形的标签
            xlabel('目标3', 'FontSize', 12, 'FontName', 'SimHei');
            ylabel('目标1', 'FontSize', 12, 'FontName', 'SimHei');
            title('每100代精英个体的目标值变化', 'FontSize', 14, 'FontName', 'SimHei');

            % 添加图例说明颜色对应代次
            legend_labels = cell(num_generations, 1);
            for i = 1:num_generations
                legend_labels{i} = ['第 ' num2str(i) ' 代'];
            end
            legend(legend_labels, 'Location', 'northeast', 'FontSize', 10, 'FontName', 'SimHei');

            % 设置图的显示效果
            set(gcf, 'Color', 'w');  % 设置背景色为白色
            grid on;  % 显示网格线
            hold off;
        end


        %% 终止时输出与可视化
        
        if Global.gen == Global.maxgen
            % 1) 评价指标（HV）
            FrontNo = NDSort(Population.objs, Population.cons, Global.N);  % 对种群进行非支配排序
            pareto_set = Population(FrontNo == 1);   % 第一帕累托前沿的个体
            [hv,~] = HV(pareto_set.objs, [0.4 0.2 -0.5]);  % 只用第一帕累托前沿个体计算HV
            disp(hv); 

            % 2) 计算“第一帕累托前沿个体”的知识点覆盖/推荐分布
            %    decs: N x D (每行一个个体的二值选题向量)
            %    Q_matrix: D x K (题-知识点关联矩阵)
            %    rec_mat: N x K (每个个体在各知识点上的覆盖数量)
            rec_mat = pareto_set.decs * double(Q_matrix);
            % 1 x K，计算第一帕累托前沿个体在各知识点上的平均分布
            rec_mean_distribution = mean(rec_mat, 1);
    
            % 3) 为了对齐可视化，与学生掌握度排序一致
            [sorted_stu, sortIndex] = sort(stu_state);    % K x 1
            sorted_rec = rec_mean_distribution(sortIndex); % 1 x K

            % 4) 绘图（左轴：平均推荐数量；右轴：学生掌握度）
            K = size(Q_matrix, 2);
            x_vals = 1:K;
            bar_width = 0.8;

            figure;
            ax1 = axes;
            bar(ax1, x_vals, sorted_rec, 'FaceColor', [0.3 0.6 1], 'BarWidth', bar_width);
            ylabel(ax1, '平均推荐习题数量（第一帕累托前沿）', 'FontName','SimHei', 'FontSize',10);
            xlabel('按掌握程度排序的知识点序列', 'FontName','SimHei', 'FontSize',10);
            ymax_bar = max(sorted_rec) * 1.1 + eps;
            set(ax1, 'YLim', [0 ymax_bar], 'XTick', [], 'FontName','SimSun');

            ax2 = axes('Position', ax1.Position);
            plot(ax2, x_vals + bar_width/2, sorted_stu, '-o', 'Color', [0.9 0.2 0.1], 'LineWidth', 1.5, 'MarkerSize', 5);
            set(ax2, 'Color', 'none', 'YLim', [0 1], 'YAxisLocation', 'right', 'XTick', [], 'FontName','SimSun');
            ax2.XAxis.Visible = 'off';

            title('知识点掌握程度与平均推荐分布（第一帕累托前沿）', 'FontName','SimHei','FontSize',12);
            legend(ax1, '平均推荐数量', 'Location','northwest', 'FontName','SimHei');
            legend(ax2, '掌握程度', 'Location','northeast', 'FontName','SimHei');
            set([ax1, ax2], 'TickLength',[0 0]);
            set(gcf, 'Color','w', 'Renderer','painters');

            % 5) 相关性（用排序后的一一对应向量）
            disp('相关性分析：第一帕累托前沿的推荐分布与学生认知状态(stu_state)');
            pearson_corr  = corr(sorted_stu', sorted_rec', 'type', 'Pearson');
            spearman_corr = corr(sorted_stu', sorted_rec', 'type', 'Spearman');
            kendall_corr  = corr(sorted_stu', sorted_rec', 'type', 'Kendall');
            fprintf('Pearson: %.6f\n',  pearson_corr);
            fprintf('Spearman: %.6f\n', spearman_corr);
            fprintf('Kendall: %.6f\n',  kendall_corr);
            disp('分析结束。');
        end

        if Global.gen == Global.maxgen
            x = Population.objs;
            y = Population.cons;
            % 目标1越小越好，归一化反向处理
            obj1 = x(:, 1);
            obj1_norm = (max(obj1) - obj1) / (max(obj1) - min(obj1) + eps);

            % 获取约束5和约束6的违反程度
            con5_viol = max(y(:,5), 0);
            con6_viol = max(y(:,6), 0);

            % 总违反程度
            total_viol = con5_viol + con6_viol;

            % 归一化违反程度，越小越好
            viol_norm = 1 - min(total_viol / (max(total_viol) + eps), 1);

            % 综合准确性
            Accuracy = 0.5 * obj1_norm + 0.5 * viol_norm;

            disp("种群平均准确性:");
            disp(mean(Accuracy));

            % 目标2：认知负荷偏差（越小越好）→ 归一化后反向
            obj2 = x(:, 2);
            obj2_norm = (max(obj2) - obj2) / (max(obj2) - min(obj2) + eps);

            % 目标3：知识点熵值是负的 → 取负数并归一化
            obj3_entropy = -x(:, 3);
            obj3_norm = (obj3_entropy - min(obj3_entropy)) / (max(obj3_entropy) - min(obj3_entropy) + eps);

            % 最终多样性
            Diversity = 0.5 * obj2_norm + 0.5 * obj3_norm;
            disp("改进后种群平均多样性：");
            disp(mean(Diversity));
            fprintf('冲突性分析结束。\n');
        end 
    end
end

%% ------------------------ 工具函数区 ------------------------

function entropy_vec = positionEntropy(decs)
    % decs: N x D 二值矩阵
    N  = size(decs,1);
    p1 = sum(decs==1,1)/N; p0 = 1 - p1;
    entropy_vec = -(p0.*log2(p0+eps) + p1.*log2(p1+eps)); % 1 x D
end

function dec_new = entropyFlipOne(dec, hotSet)
    % 在高熵位集合中随机翻 1 位；再随机补一位相反翻转，尽量维持解稀疏度
    dec_new = dec;
    if isempty(hotSet), return; end
    p = hotSet(randi(numel(hotSet)));
    dec_new(p) = 1 - dec_new(p);
    % 可按需再随机找一位做反向翻，交由 repairC1_num 严格校正题数
end
