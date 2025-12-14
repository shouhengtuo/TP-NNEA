function A = seedArchiveFromFront(ParetoP, Q, Amax)
    A = struct('g',{},'dec',{},'objs',{});
    for i=1:numel(ParetoP)
        dec = ParetoP(i).decs;        % 1×D
        g   = dec*Q;                  % 1×K 概念计数
        A(end+1).g = g;            %#ok<AGROW>
        A(end  ).dec = dec;
        A(end  ).objs= ParetoP(i).objs;
    end
    % 去重（按 g）
    G = cat(1,A.g);
    [~,uni] = unique(round(G,6),'rows');
    A = A(uni);
    if numel(A)>Amax, A = A(1:Amax); end
end