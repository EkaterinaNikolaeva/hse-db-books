CREATE OR REPLACE FUNCTION bookmetrics.get_actual_book_in_shop_id(
    p_book_id INTEGER,
    p_shop_id INTEGER
) 
RETURNS INTEGER AS $$
DECLARE
    answer INTEGER;
BEGIN
    SELECT record_id INTO answer
    FROM bookmetrics.book_in_shop
    WHERE book_id = p_book_id
      AND shop_id = p_shop_id
      AND now() BETWEEN valid_from AND valid_to;

    IF answer IS NULL THEN
        RAISE EXCEPTION 'There are no actual books in the shop for the given IDs';
    END IF;

    RETURN answer;
END;
$$

LANGUAGE plpgsql;