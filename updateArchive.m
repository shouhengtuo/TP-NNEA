function A = updateArchive(A, Population, Q, Amax)
    FrontNo = NDSort(Population.objs, Population.cons, numel(Population));
    idx = find(FrontNo==1);
    if isempty(idx), return; end
    PF = Population(idx);
    for i=1:numel(PF)
        dec = PF(i).decs; g = dec*Q;
        A(end+1).g = g;              %#ok<AGROW>
        A(end  ).dec = dec;
        A(end  ).objs= PF(i).objs;
    end
    % 去重
    G = cat(1,A.g);
    [~,uni] = unique(round(G,6),'rows');
    A = A(uni);
    % 简单归一化评分（越小越好）
    Objs = cat(1,A.objs);
    rng  = max(Objs)-min(Objs); rng(rng==0)=1;
    score = sum((Objs - min(Objs))./rng,2);
    [~,ord]= sort(score,'ascend');
    A = A(ord);
    if numel(A)>Amax, A = A(1:Amax); end
end