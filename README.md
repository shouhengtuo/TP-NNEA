# TP-NNEA: Two-Phase Neural Network Evolution Algorithm for Personalized Exercise Recommendation

## 📚 Algorithm Overview

**TP-NNEA (Two-Phase Neural Network Evolution Algorithm)** is a novel personalized exercise recommendation method that combines neural network dimensionality reduction with multi-objective optimization techniques. This algorithm has been submitted to the journal *Computer Education* and is currently under review.

**Authors**: Shouheng Tuo, Yong Zhao
**Paper Title**: Integrating Cognitive Diagnosis and Multi-Objective Optimization for Personalized Exercise Recommendation: A Two-Stage Approach Based on Neural Network Dimensionality Reduction
**Journal**: Computer Education (Under Review)

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
- `DyN-MOEA/DyN_MOEA.m` - 增强版本，具有自适应特性

### 神经网络组件
- `DyN-MOEA/FCNForward.m` - 神经网络前向传播
- `DyN-MOEA/INDIVIDUAL.m` - 个体表示和目标计算

### 进化算子
- `DyN-MOEA/Operator_DynDE.m` - 动态差分进化，包含4种策略
- `DyN-MOEA/guidedFlipByConcept.m` - 概念引导变异
- `DyN-MOEA/DiversityMutation.m` - 多样性增强变异
- `DyN-MOEA/entropyFlipOne.m` - 熵驱动变异

### 选择和档案管理
- `DyN-MOEA/EnvironmentalSelection_DynMOEA.m` - 具有多样性保持的环境选择
- `DyN-MOEA/ArchiveManager.m` - 精英档案管理
- `DyN-MOEA/TournamentSelection.m` - 二进制锦标赛选择
- `DyN-MOEA/NDSort.m` - 非支配排序

### 实用函数
- `DyN-MOEA/CalFitness1.m` - 适应度计算
- `DyN-MOEA/repairC1_num.m` - 约束修复
- `DyN-MOEA/seedArchiveFromFront.m` - 档案初始化
- `DyN-MOEA/updateArchive.m` - 档案更新
- `DyN-MOEA/extractPopulationData.m` - 数据提取
- `DyN-MOEA/positionEntropy.m` - 位置熵计算
- `DyN-MOEA/iif.m` - 内联if函数

---

## 📊 问题定义文件

### 习题推荐问题
- `DyN-MOEA/Exerciese Recommendation/ER.m` - 增强问题公式化
- `DyN-MOEA/Exerciese Recommendation/Exercise_RC.m` - 替代公式化

### 数据集
- `DyN-MOEA/Exerciese Recommendation/dataSet1.mat` - ASSISTments数据集
- `DyN-MOEA/Exerciese Recommendation/dataSet2.mat` - JunYi数据集

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

### 性能比较
| 算法 | 皮尔逊 | 斯皮尔曼 | 肯德尔 | HV |
|-----------|----------|----------|---------|----|
| CMOEA/D  | -0.280  | -0.243   | -0.185  | 0.544 |
| NSGA-II   | -0.163  | -0.117   | -0.082  | 0.545 |
| CCMO      | -0.123  | -0.106   | -0.072  | 0.538 |
| SparseEA2 | -0.412  | -0.359   | -0.265  | 0.539 |
| CoE-DCDP  | -0.101  | -0.028   | -0.015  | 0.519 |
| **TP-NNEA** | **-0.391** | **-0.181** | **-0.594** | **0.554** |

---

## 💻 系统要求

### 软件
- MATLAB R2019b或更高版本
- 优化工具箱
- 统计和机器学习工具箱（可选）

### 硬件
- **最低配置**: 4GB内存，双核CPU
- **推荐配置**: 8GB+内存，四核+CPU
- **大型数据集**: 建议GPU加速

---

## 📝 Citation

If you use this algorithm in your research, please cite:

```bibtex
@article{tuo2024integrating,
  title={Integrating Cognitive Diagnosis and Multi-Objective Optimization for Personalized Exercise Recommendation: A Two-Stage Approach Based on Neural Network Dimensionality Reduction},
  author={Tuo, Shouheng and Zhao, Yong},
  journal={Computer Education},
  year={2024},
  note={Under Review}
}
```

---

## 📄 许可证

此代码仅用于研究目的。使用此平台的所有出版物应确认使用TP-NNEA并参考原始论文。

---

## 📧 联系方式

有关算法或实现的问题，请参考原始论文或联系作者。

---

## 📁 测试和分析工具

### 快速测试（无需数据集）
```matlab
% 运行快速性能测试（使用模拟数据）
>> QuickPerformanceTest
```

**输出**:
- 控制台性能指标显示
- `Quick_Performance_Test.png` - 可视化

### 完整评估（需要数据集）
```matlab
% 运行完整性能评估
>> AlgorithmPerformanceTest
```

**输出**:
- 控制台统计摘要
- `TP_NNEA_Performance_Analysis.png` - 综合可视化
- `TP_NNEA_Results.csv` - 每个学生的详细指标
- `TP_NNEA_Summary.mat` - 聚合统计

### 详细分析报告
```matlab
% 显示综合算法分析
>> DetailedAnalysisReport
```

**输出**:
- 涵盖以下内容的详细控制台报告：
  - 算法架构
  - 优势和局限性
  - 性能基准
  - 建议

---

**Last Updated**: 2024-12-14
**Algorithm Version**: TP-NNEA v1.0
**Status**: Under Review at Computer Education Journal
