# Домашнее задание к занятию «SQL. Часть 2» - Яковлев Кирилл

### Задание 1
Одним запросом получите информацию о магазине, в котором обслуживается более 300 покупателей, и выведите в результат следующую информацию:
- фамилия и имя сотрудника из этого магазина;
- город нахождения магазина;
- количество пользователей, закреплённых в этом магазине.

**Запрос:**
```sql
SELECT 
    st.last_name AS фамилия_сотрудника,
    st.first_name AS имя_сотрудника,
    ci.city AS город,
    COUNT(c.customer_id) AS количество_покупателей
FROM store s
JOIN customer c ON s.store_id = c.store_id
JOIN staff st ON s.store_id = st.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
GROUP BY s.store_id, st.last_name, st.first_name, ci.city
HAVING COUNT(c.customer_id) > 300;
```

**Результат:**
![Задание 1](https://github.com/djimboliv/8-03-hw/tree/main/img/task_1.png)

---

### Задание 2
Получите количество фильмов, продолжительность которых больше средней продолжительности всех фильмов.

**Запрос:**
```sql
SELECT 
    COUNT(film_id) AS количество_фильмов
FROM film
WHERE length > (
    SELECT AVG(length) 
    FROM film
);
```

**Результат:**
![Задание 2](https://github.com/djimboliv/8-03-hw/tree/main/img/task_2.png)

---

### Задание 3
Получите информацию, за какой месяц была получена наибольшая сумма платежей, и добавьте информацию по количеству аренд за этот месяц.

**Запрос:**
```sql
SELECT 
    STRFTIME('%Y-%m', payment_date) AS месяц,
    ROUND(SUM(amount), 2) AS сумма_платежей,
    COUNT(rental_id) AS количество_аренд
FROM payment
GROUP BY STRFTIME('%Y-%m', payment_date)
ORDER BY сумма_платежей DESC
LIMIT 1;
```

**Результат:**
![Задание 3](https://github.com/djimboliv/8-03-hw/tree/main/img/task_3.png)