%% ========== 约束 C1：保证选题数量恰为 num ==========
function dec_fix = repairC1_num(dec, num)
    % 确保“选题数 = num”
    dec_fix = dec;
    s = sum(dec_fix);
    if s>num
        idx1 = find(dec_fix==1);
        drop = idx1(randperm(numel(idx1), s-num));
        dec_fix(drop)=0;
    elseif s<num
        idx0 = find(dec_fix==0);
        if ~isempty(idx0)
            add = idx0(randperm(numel(idx0), min(num-s,numel(idx0))));
            dec_fix(add)=1;
        end
    end
end