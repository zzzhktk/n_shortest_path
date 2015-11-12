%data  原始数据矩阵，记录各个边的权值
%array_src  源区域包含的点
%array_dst  目的区域包含的点
%path_num   需要求出前path_num条最短路径
function n_shortest_paths(data, C, maxc, T, maxt, array_src, array_dst, path_num)
    src_num = size(array_src, 2);
    dst_num = size(array_dst, 2);
    
    %将源点和目的点组成的组合存入group中
    group_lines = src_num * dst_num;
    group = cell(group_lines, 2);
    group_index = 1;
    for x=1:src_num
        for y=1:dst_num
            group{group_index, 1} = array_src(x);
            group{group_index, 2} = array_dst(y);
            group_index = group_index + 1;
        end
    end
    
    %一个数据集的最短路径包含以下信息
    %data 数据矩阵
    %src  源点
    %dst  终点
    %distance   计算出的最短路径的距离矩阵
    %router     计算出的最短路径的路径矩阵
    %isdel      是否被删除
    
    %shortest_cell ：存放前n条最短路径的结构
    %shortest_cell_num  : shortest_cell 中元素的个数
    %mediated_cell : 存放已经计算出的路径
    %mediated_cell_num : mediated_cell 中元素个数    
    shortest_cell = cell(1, path_num);
    shortest_cell_num = 0;
    mediated_cell = cell(1, path_num);
    mediated_cell_num = 0;
    
    %计算data集的最短路径,将group中各个起始点对应的元素加入到mediated_cell中
    [distance,router]=floyd(data);
    for index=1:group_lines
        element.data = data;
        element.src = group{index, 1};
        element.dst = group{index, 2};
        element.distance = distance;
        element.router = router;
        element.isdel = 0;
        %如果这条路是无穷大，即不通，将element标记被删除状态
        if element.distance(element.src, element.dst) == inf  
            element.isdel = 1;
        end
        
        mediated_cell_num = mediated_cell_num + 1;
        mediated_cell{1, mediated_cell_num} = element;
    end
    
    %1、从mediated_cell的中找出最短的那条路径min element，加入到shorted_cell中
    %2、计算min element的子集，加入到mediated_cell中
    %3、重复1，2步，直到找到前n条最短路径
    while shortest_cell_num < path_num
        %new_index 代表本次循环中第一个新加入到shortest_cell_num中的元素的地址
        new_index = shortest_cell_num + 1;
        
        %找出mediated_cell中第一个未标记被删除的元素
        first_index = -1;
        for index=1:mediated_cell_num
            if mediated_cell{1, index}.isdel == 0
                first_index = index;
                break
            end
        end
        
        %当一个数据集的子集没有一条路是通的，那么上个循环中新加入到 
        %mediated_cell中的未被标记为删除状态子集数就会是0，
        %现在就会找不到未被标记删除的元素。
        %比如从A到B总共就3条路可通，现在却要求前5条最短路径，弟4、5条是不存在的。
        if first_index == -1
            fprintf('the total path may be %d, but yao want to get the shortest %d path \n', shortest_cell_num, path_num);
            break
        end
        
        %从mediated_cell的中找出最短的那条路径
        element = mediated_cell{1,first_index};
        min_value = element.distance(element.src, element.dst);
        min_index = first_index;
        for index=first_index+1:mediated_cell_num
            if mediated_cell{1, index}.isdel == 1
                continue
            end
            element = mediated_cell{1, index};
            if min_value > element.distance(element.src, element.dst)
                min_value = element.distance(element.src, element.dst);
                min_index = index;
            end
        end
            
        %将第一个最短的这条路径加入到shorted_cell中
        %同一个值可能对应多条路径
        %需要判断shortest_cell中是否已经有这个路径了
        %！！！！ 加入到 shortest_cell 中 ！！！！
        if is_match_condition(C, maxc, T, maxt, mediated_cell{1, min_index}) == 1 && ...
           is_already_exist(shortest_cell, shortest_cell_num, mediated_cell{1, min_index}) == 0
            shortest_cell_num = shortest_cell_num + 1;
            shortest_cell{1, shortest_cell_num} = mediated_cell{1, min_index}; 
        end
        mediated_cell{1, min_index}.isdel = 1;
        
        %fprintf('1111111 shortest_cell_num is %d  \n', shortest_cell_num);
        %element = shortest_cell{1, shortest_cell_num};
        %element.data
        %element.src
        %element.dst
        %element.distance
        %element.router
        %element.isdel
        
        %1、两个不同的数据集算出的路径可能是同一条路径，
        %   要将与最短路径重复的元素从mediated_cell中去掉
        %2、不同路径的值可能是一样的，要将值相同的路径取出来
        cmp_value = min_value;
        cmp_index = new_index - 1;     
        while cmp_index < shortest_cell_num
            cmp_index = cmp_index + 1;
            cmp_element = shortest_cell{1, cmp_index};
            
            for index=1:mediated_cell_num
                if mediated_cell{1, index}.isdel == 1
                    continue
                end
                element = mediated_cell{1, index};
                if cmp_value ~= element.distance(element.src, element.dst)
                    continue
                end
                if path_is_same(cmp_element, element) == 1
                    mediated_cell{1, index}.isdel = 1;
                else
                    %值相同，但是路径不同，这是本次循环中的第二个最短路径
                    %！！！！！ 加入到shortest_cell 中 ！！！！
                    if is_match_condition(C, maxc, T, maxt, mediated_cell{1, min_index}) == 1 && ...
                       is_already_exist(shortest_cell, shortest_cell_num, mediated_cell{1, index}) == 0
                        shortest_cell_num = shortest_cell_num + 1;
                        shortest_cell{1, shortest_cell_num} = mediated_cell{1, index};
                    end
                    mediated_cell{1, index}.isdel = 1;
                end
            end
        end
        %{
        fprintf('******************************************\n')
        for index=1:shortest_cell_num
            element = shortest_cell{1, index};
            fprintf('shortest_cell %d, src is %d, dst is %d, isdel is %d\n', index, element.src, element.dst, element.isdel);
            fprintf('data is \n');
            element.data
            fprintf('distance is \n');
            element.distance
            fprintf('router is \n');
            element.router
        end
        fprintf('******************\n')
        for index=1:mediated_cell_num
            element = mediated_cell{1, index};
            fprintf('mediated_cell %d, src is %d, dst is %d, isdel is %d\n', index, element.src, element.dst, element.isdel);
            fprintf('data is \n');
            element.data
            fprintf('distance is \n');
            element.distance
            fprintf('router is \n');
            element.router
        end
        %}
        
        %如果找到了path_num条路径，跳出循环
        if shortest_cell_num >= path_num
            break
        end
        
        %计算刚加入到shortest_cell中的最短路径的各个子集的最短路径，加入到mediated_cell中
        for parent_index=new_index:shortest_cell_num
            element = shortest_cell{1, parent_index};
            subset = get_subset(element.data, element.src, element.dst, element.router);
            e_num = size(subset, 2);
            %e_num
            for index=1:e_num
                mediated_cell_num = mediated_cell_num + 1;
                mediated_cell{1, mediated_cell_num} = subset{1, index};

                %fprintf('22222222 mediated_cell_num  is %d \n', mediated_cell_num);
                %element = mediated_cell{1, mediated_cell_num};
                %element.data
                %element.src
                %element.dst
                %element.distance
                %element.router
                %element.isdel
            end
        end
    end
    
    fprintf('============================================ \n');
    for index=1:shortest_cell_num
        element = shortest_cell(1, index);
        
        fprintf('============== %d ===============\n', index);
        element = shortest_cell{1, index};
        output_element(element, C, T);
    end
    
 function output_element(element, C, T)
    fprintf('(%d, %d)   %d      ', element.src, element.dst, element.distance(element.src, element.dst));
    
    sides=get_sides_of_path(element.router, element.src, element.dst);
    side_num = size(sides, 1);
    for index=1:side_num
        fprintf('%d -- ', sides(index, 1));
    end
    fprintf('%d\n', element.dst);
    
    [sumc, sumt]=get_sumc_and_sumt(C, T, element);
    fprintf('c is %d \n', sumc);
    fprintf('t is %d \n', sumt);
    
    fprintf('distance is \n');
    element.distance
    fprintf('router is \n');
    element.router
    

function result=is_already_exist(current_cell, e_num, element)
    result = 0;
    for index=1:e_num
        current_e = current_cell{1, index};
        if current_e.distance(current_e.src, current_e.dst) ~= element.distance(element.src, element.dst)
            continue
        end
        if path_is_same(current_e, element) == 1
        	result = 1;
        end
    end

function result=is_match_condition(C, maxc, T, maxt, element)
    result = 0;
    [sumc, sumt]=get_sumc_and_sumt(C, T, element);
    if sumc <= maxc && sumt <= maxt
        result = 1;
    end
    
function [sumc,sumt]=get_sumc_and_sumt(C, T, element)
    sumc = 0;
    sumt = 0;
    sides=get_sides_of_path(element.router, element.src, element.dst);
    side_num = size(sides, 1);
    for index=1:side_num
        x = sides(index, 1);
        y = sides(index, 2);
        sumc = sumc + C(x, y);
        sumt = sumt + T(x, y);
    end
    

    
function result=path_is_same(element1, element2)
    result = 1;
    if element1.src ~= element2.src || element1.dst ~= element2.dst
        result = 0;
        return
    end
    
    prev1 = element1.src;
    prev2 = element2.src; 
    while prev1 ~= element1.dst && prev2 ~= element2.dst
        next1 = element1.router(prev1, element1.dst);
        next2 = element2.router(prev2, element2.dst);
        if next1 ~= next2
            result = 0;
            return
        end
        prev1 = next1;
        prev2 = next2;
    end
    
    if prev1 ~= prev2
        result = 0
    end

    

%计算当前最短路径子集的最短路径
%router为当前最短路径集
function subset=get_subset(data, src, dst, router)
    sides=get_sides_of_path(router, src, dst);
    side_num = size(sides, 1);
    
    subset = cell(1, side_num);
    for index=1:side_num
        subdata = create_sub_data(data, sides(index, 1), sides(index, 2)); 
        
        %fprintf('get_subset : index is %d, x is %d, y is %d\n', index,  sides(index, 1), sides(index, 2));
        %subdata
        
        [distance, router] = floyd(subdata);
        
        element.data = subdata;
        element.src = src;
        element.dst = dst;
        element.distance = distance;
        element.router = router;
        element.isdel = 0;
        
        %如果这条路是无穷大，即不通，将element标记被删除状态
        if element.distance(element.src, element.dst) == inf  
            element.isdel = 1;
        end
        subset{1, index} = element;
    end
    

%将path集中的一条边设置为无穷大，生成一个子集
function subdata=create_sub_data(data, x, y)
    subdata = data;
    %fprintf('create_sub_data: x is %d, y is %d\n', x, y);
    subdata(x, y) = inf;
    
%得出path的每条边，存在sides中   
function sides=get_sides_of_path(router, src, dst)
    index = 1;
    prev = src;
    next = router(src, dst);
    while prev ~= dst
        sides(index, 1) = prev;
        sides(index, 2) = next;
        %fprintf('get_sides_of_path : index %d : %d, %d\n', index, prev, next);
        
        index = index + 1;
        prev = next;
        next = router(next, dst);
    end
    %fprintf('there are %d side\n', size(sides, 1));
    

function [d,r]=floyd(original)
 %floyd.m
 %采用floyd算法计算图a中每对顶点最短路
 %d是矩离矩阵
 %r是路由矩阵
    n=size(original,1);
    d=original;
     for i=1:n
         for j=1:n
                 r(i,j)=j;
          end 
     end 

      for k=1:n
           for i=1:n
                for j=1:n
                     if d(i,k)+d(k,j)<d(i,j)
                          d(i,j)=d(i,k)+d(k,j);
                           r(i,j)=r(i,k);
                      end 
                 end 
           end
      end
