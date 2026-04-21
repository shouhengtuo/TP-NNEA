# TP-NNEA: Two-Phase Neural Network Evolution Algorithm for Personalized Exercise Recommendation

## 📚 Algorithm Overview

**TP-NNEA (Two-Phase Neural Network Evolution Algorithm)** is a novel personalized exercise recommendation method that combines neural network dimensionality reduction with multi-objective optimization techniques. This algorithm has been submitted to the journal *applied soft computing* and is currently under review.

**Authors**: Shouheng Tuo, Yong Zhao
**Paper Title**: Integrating Cognitive Diagnosis and Multi-Objective Optimization for Personalized Exercise Recommendation: A Two-Stage Approach Based on Neural Network Dimensionality Reduction


---

## 🎯 问题陈述

个性化习题组组装任务（PEGA）旨在基于学生的知识掌握水平，从庞大的习题库中为其推荐最优的习题集。这被构建为一个约束多目标优化问题（CMOP），包含三个目标：

1. **薄弱知识巩固** - 加强掌握较差的知识概念
2. **认知负荷平衡** - 维持适当的习题难度
3. **知识多样性** - 确保广泛的知识覆盖

---

## 🔬 算法架构

### 第一阶段：神经网络降维
- **目的**: 将高维离散优化转化为连续权重优化
- **方法**: 基于SA-MODDE优化的共享权重神经网络
- **输入**: 学生知识状态 + Q矩阵 + 习题特征
- **输出**: 习题选择概率

### 第二阶段：混合二进制变异
- **目的**: 使用领域知识进行精细调优
- **组成部分**:
  - 目标驱动引导（40%）：基于精英档案的概念引导
  - 信息增益引导（30%）：基于熵的变异
  - 多样性变异（30%）：知识多样性增强

### 动态阶段转换
- 基于适应度变化率的自适应转换
- 使用滑动窗口中位数进行收敛监控
- 自调节阶段比例：[0.40, 0.85]

---

## 📁 核心实现文件

### 主算法
- `TP_NNEA.m` - 原始算法实现（二进制文件，无法直接查看）






---

## 🎯 优化目标

### 目标1：薄弱知识巩固（最小化）
学生掌握度与习题分布之间的加权皮尔逊相关系数：
```
O1 = -Σ(w_k × ((s_k - μ_s) / σ_s) × (y_k - μ_y) / σ_y) / Σw_k
```

其中权重计算：
```
w_k = 1 / (1 + exp(β × (s_k - θ)))
```

### 目标2：认知负荷平衡（最小化）
与目标认知负荷（0.6）的偏差：
```
O2 = |avg_difficulty - 0.6|
```

### 目标3：知识多样性（最大化）
知识概念分布的熵：
```
O3 = -Σ(p_k × log(p_k + ε))
```

---

## 🚀 使用说明

### 基本使用
```matlab
% 设置问题参数
Global.N = 100;        % 种群大小
Global.maxgen = 600;   % 最大迭代次数
[stuId, num] = Global.ParameterSet(1, 50);  % 学生ID，习题数量

% 运行算法
DyN_MOEA(Global);
```

### 数据集要求
数据集文件中的必需字段：
- `student_emb` - 学生知识嵌入（N × K）
- `k_difficulty` - 习题难度（M × 级别）
- `Q_matrix` - 习题-概念映射（M × K）
- `exercise_log` - 学生习题历史（N × M）
- `knowledge_log` - 知识掌握度（N × K）
- `predition` - 预测成功率（N × M）

---

## 📈 算法特性

### 神经网络架构
- **输入层**: 学生状态 + Q矩阵 + 难度
- **隐藏层**: [25, 50]个神经元，使用leaky ReLU
- **输出层**: 用于概率的sigmoid激活
- **优化**: 具有自适应F和Cr参数的SA-MODDE

### 多策略差分进化
1. **DE/rand/1**: v = x_r1 + F×(x_r2 - x_r3)
2. **DE/best/1**: v = x_best + F×(x_r1 - x_r2)
3. **DE/current-to-best/1**: v = x_i + F×(x_best - x_i) + F×(x_r1 - x_r2)
4. **DE/rand/2**: v = x_r1 + F×(x_r2 - x_r3) + F×(x_r4 - x_r5)

### 自适应参数控制
- 自适应F和Cr参数
- 基于成功率的策略选择
- 基于收敛的动态阶段转换

---

## 📊 性能指标

### 收敛指标
- **超体积（HV）**: 帕累托前沿质量
- **世代距离**: 收敛速度

### 解质量
- **皮尔逊相关系数**: 学生掌握度与习题分布
- **斯皮尔曼等级相关**: 基于等级的相关
- **肯德尔τ**: 序数关联

### 多样性指标
- **熵**: 知识概念多样性
- **覆盖率**: 知识空间探索

---

## 🔬 实验结果

### 数据集
- **ASSISTments**: 4,163名学生，17,746道习题，123个概念
- **JunYi**: 1,000名学生，712道习题，39个概念



---

## 📝 Citation

If you use this algorithm in your research, please cite:

```bibtex
@article{tuo2024integrating,
  title={Integrating Cognitive Diagnosis and Multi-Objective Optimization for Personalized Exercise Recommendation: A Two-Stage Approach Based on Neural Network Dimensionality Reduction},
  author={Tuo, Shouheng and Zhao, Yong},
  journal={Computer Education},
  year={2025},
  note={Under Review}
}
```



