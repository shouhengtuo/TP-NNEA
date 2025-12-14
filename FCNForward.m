function Output = FCNForward(Input, instance, s_list)
% Fully connected neural network forward propagation
% The function input includes a set of neural network weights, 
% problem information, and a list of neural network structures
    
%------------------------------- Copyright --------------------------------
% Copyright (c) 2024 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87.
%--------------------------------------------------------------------------

% 输入参数解释：
% Input：神经网络的权重集，大小为 N×weight_length，其中 N 为权重集的数量  
% instance: 问题实例，即输入到神经网络的特征向量
% s_list：神经网络的结构列表

    % 初始化输出矩阵
    Output = zeros(size(Input, 1), size(instance, 1));
    
    % 循环处理每组权重
    for n = 1 : size(Input, 1)
        % 初始化当前层的输出为输入实例
        output = instance;
        pointer = 1;
        
        % 遍历神经网络的每一层结构
        for i = 1 : size(s_list, 1)
            % 获取当前层的权重和偏置
            if s_list(i, 2) ~= -1
                % 计算当前层的权重维度
                weight = Input(n, pointer:pointer + s_list(i, 1) * s_list(i, 2) - 1);
                pointer = pointer + s_list(i, 1) * s_list(i, 2);
                % 权重矩阵变形并计算输出
                output = output * reshape(weight, [s_list(i, 1), s_list(i, 2)]);
            else
                % 获取偏置项
                bias = Input(n, pointer:pointer + s_list(i, 1) - 1);
                pointer = pointer + s_list(i, 1);
                % 添加偏置
                output = output + bias;
                % 根据层类型应用激活函数
                if i == size(s_list, 1)
                    % 最后一层使用sigmoid激活函数
                    output = sigmoid(output);
                    Output(n, :) = output;
                else
                    % 隐藏层使用leaky_relu激活函数
                    output = leaky_relu(output);
                end
            end
        end
    end
end

% leaky_relu 激活函数，如果输入 x 大于 0 则输出 x，否则输出 0.01 * x
function y = leaky_relu(x)
    y = x .* (x > 0) + 0.01 * x .* (x <= 0);
end

% sigmoid 激活函数，将输入值映射到 0 到 1 的范围
function y = sigmoid(x)
    y = 1 ./ (1 + exp(-x));
end