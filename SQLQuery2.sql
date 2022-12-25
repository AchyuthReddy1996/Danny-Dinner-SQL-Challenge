-- Displaying table of sales
select * from sales;

-- Displaying table of menu
select * from menu;

-- What is the total amount each customer spent at the restaurant?
select sales.customer_id, sum(menu.price) as total_spent 
from sales 
join menu 
on sales.product_id = menu.product_id 
group by customer_id;

-- How many days has each customer visited the restaurant?
select customer_id, count(Distinct(order_date)) as TotalDaysofOrder
from sales 
group by customer_id;

-- What was the first item from the menu purchased by each customer?
select sales_temp.customer_id, menu.product_name
from menu
join
	(
		select customer_id, product_id, 
		ROW_NUMBER() over( partition by customer_id order by order_date) as rn
		from sales
	) as sales_temp
on 
sales_temp.product_id = menu.product_id
where rn = 1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
select menu.product_name, cnt
from menu
join
(
	select top 1 product_id, count(*) as cnt
	from sales
	group by product_id
	order by cnt desc
) as temp
on temp.product_id = menu.product_id ; 


-- Which item was the most popular for each customer?
with cnt_tble as 
(select customer_id, product_id, count(*) as cnt
from
sales
group by customer_id, product_id),
rnk_tble as (select customer_id,product_id, row_number() over(partition by customer_id order by cnt desc) as ranknumber from cnt_tble)

select customer_id,menu.product_name
from rnk_tble join menu on rnk_tble.product_id = menu.product_id
where ranknumber = 1;

-- Which item was purchased first by the customer after they became a member?
select customer_id, order_date
from
(select sales.customer_id,order_date ,row_number() over(partition by members.customer_id order by order_date) as rn from members 
full outer join
sales
on sales.customer_id = members.customer_id
where sales.order_date > members.join_date ) as tmp
where rn = 1;

--Which item was purchased just before the customer became a member?
select customer_id, order_date
from
(select sales.customer_id,order_date ,row_number() over(partition by members.customer_id order by order_date desc) as rn from members 
full outer join
sales
on sales.customer_id = members.customer_id
where sales.order_date < members.join_date or members.join_date is NULL) as tmp
where rn = 1;

-- What is the total items and amount spent for each member before they became a member?
select sales.customer_id, sum(price) as total_spent from sales 
full outer join members 
on members.customer_id = sales.customer_id
full outer join menu
on sales.product_id = menu.product_id
where sales.order_date < members.join_date or members.join_date is NULL
group by sales.customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id, sum(points) as total_points
from 
(
	select product_id, (case when product_name = 'sushi' then  price * 20 else price * 10 end) as points 
	from menu
) tmp
join
sales
on sales.product_id = tmp.product_id
group by sales.customer_id;


-- In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select  sales.customer_id, sum(case when day(members.join_date) - day(sales.order_date) <= 7 and day(members.join_date) - day(sales.order_date) >= 0  then  price * 20 else price * 10 end) as AB_sales_jan
from sales 
full outer join members 
on members.customer_id = sales.customer_id
full outer join menu
on sales.product_id = menu.product_id
where sales.order_date >= members.join_date and month(sales.order_date) = 1
group by sales.customer_id;
