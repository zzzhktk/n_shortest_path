%data  ԭʼ���ݾ��󣬼�¼�����ߵ�Ȩֵ
%array_src  Դ��������ĵ�
%array_dst  Ŀ����������ĵ�
%path_num   ��Ҫ���ǰpath_num�����·��
function n_shortest_paths(data, C, maxc, T, maxt, array_src, array_dst, path_num)
    src_num = size(array_src, 2);
    dst_num = size(array_dst, 2);
    
    %��Դ���Ŀ�ĵ���ɵ���ϴ���group��
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
    
    %һ�����ݼ������·������������Ϣ
    %data ���ݾ���
    %src  Դ��
    %dst  �յ�
    %distance   ����������·���ľ������
    %router     ����������·����·������
    %isdel      �Ƿ�ɾ��
    
    %shortest_cell �����ǰn�����·���Ľṹ
    %shortest_cell_num  : shortest_cell ��Ԫ�صĸ���
    %mediated_cell : ����Ѿ��������·��
    %mediated_cell_num : mediated_cell ��Ԫ�ظ���    
    shortest_cell = cell(1, path_num);
    shortest_cell_num = 0;
    mediated_cell = cell(1, path_num);
    mediated_cell_num = 0;
    
    %����data�������·��,��group�и�����ʼ���Ӧ��Ԫ�ؼ��뵽mediated_cell��
    [distance,router]=floyd(data);
    for index=1:group_lines
        element.data = data;
        element.src = group{index, 1};
        element.dst = group{index, 2};
        element.distance = distance;
        element.router = router;
        element.isdel = 0;
        %�������·������󣬼���ͨ����element��Ǳ�ɾ��״̬
        if element.distance(element.src, element.dst) == inf  
            element.isdel = 1;
        end
        
        mediated_cell_num = mediated_cell_num + 1;
        mediated_cell{1, mediated_cell_num} = element;
    end
    
    %1����mediated_cell�����ҳ���̵�����·��min element�����뵽shorted_cell��
    %2������min element���Ӽ������뵽mediated_cell��
    %3���ظ�1��2����ֱ���ҵ�ǰn�����·��
    while shortest_cell_num < path_num
        %new_index ������ѭ���е�һ���¼��뵽shortest_cell_num�е�Ԫ�صĵ�ַ
        new_index = shortest_cell_num + 1;
        
        %�ҳ�mediated_cell�е�һ��δ��Ǳ�ɾ����Ԫ��
        first_index = -1;
        for index=1:mediated_cell_num
            if mediated_cell{1, index}.isdel == 0
                first_index = index;
                break
            end
        end
        
        %��һ�����ݼ����Ӽ�û��һ��·��ͨ�ģ���ô�ϸ�ѭ�����¼��뵽 
        %mediated_cell�е�δ�����Ϊɾ��״̬�Ӽ����ͻ���0��
        %���ھͻ��Ҳ���δ�����ɾ����Ԫ�ء�
        %�����A��B�ܹ���3��·��ͨ������ȴҪ��ǰ5�����·������4��5���ǲ����ڵġ�
        if first_index == -1
            fprintf('the total path may be %d, but yao want to get the shortest %d path \n', shortest_cell_num, path_num);
            break
        end
        
        %��mediated_cell�����ҳ���̵�����·��
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
            
        %����һ����̵�����·�����뵽shorted_cell��
        %ͬһ��ֵ���ܶ�Ӧ����·��
        %��Ҫ�ж�shortest_cell���Ƿ��Ѿ������·����
        %�������� ���뵽 shortest_cell �� ��������
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
        
        %1��������ͬ�����ݼ������·��������ͬһ��·����
        %   Ҫ�������·���ظ���Ԫ�ش�mediated_cell��ȥ��
        %2����ͬ·����ֵ������һ���ģ�Ҫ��ֵ��ͬ��·��ȡ����
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
                    %ֵ��ͬ������·����ͬ�����Ǳ���ѭ���еĵڶ������·��
                    %���������� ���뵽shortest_cell �� ��������
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
        
        %����ҵ���path_num��·��������ѭ��
        if shortest_cell_num >= path_num
            break
        end
        
        %����ռ��뵽shortest_cell�е����·���ĸ����Ӽ������·�������뵽mediated_cell��
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

    

%���㵱ǰ���·���Ӽ������·��
%routerΪ��ǰ���·����
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
        
        %�������·������󣬼���ͨ����element��Ǳ�ɾ��״̬
        if element.distance(element.src, element.dst) == inf  
            element.isdel = 1;
        end
        subset{1, index} = element;
    end
    

%��path���е�һ��������Ϊ���������һ���Ӽ�
function subdata=create_sub_data(data, x, y)
    subdata = data;
    %fprintf('create_sub_data: x is %d, y is %d\n', x, y);
    subdata(x, y) = inf;
    
%�ó�path��ÿ���ߣ�����sides��   
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
 %����floyd�㷨����ͼa��ÿ�Զ������·
 %d�Ǿ������
 %r��·�ɾ���
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
