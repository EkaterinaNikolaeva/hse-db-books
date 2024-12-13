import argparse
import sqlalchemy
import sqlalchemy.orm


BASE = sqlalchemy.orm.declarative_base()


class Author(BASE):
    __tablename__ = "author"
    __table_args__ = {"schema": "bookmetrics"}
    author_id = sqlalchemy.Column(
        sqlalchemy.Integer, primary_key=True, autoincrement=True
    )
    name = sqlalchemy.Column(sqlalchemy.String, nullable=False)


class Book(BASE):
    __tablename__ = "book"
    __table_args__ = (
        sqlalchemy.CheckConstraint(
            "(regexp_match(isbn, '^\\d{10}$') is not null or regexp_match(isbn, '^\\d{13}$') is not null)",
            name="check_isbn_format",
        ),
        {"schema": "bookmetrics"},
    )
    book_id = sqlalchemy.Column(
        sqlalchemy.Integer, primary_key=True, autoincrement=True
    )
    title = sqlalchemy.Column(sqlalchemy.String, nullable=False)
    isbn = sqlalchemy.Column(sqlalchemy.String(13))
    edition = sqlalchemy.Column(sqlalchemy.String)


class AuthorXBook(BASE):
    __tablename__ = "author_x_book"
    __table_args__ = {"schema": "bookmetrics"}
    record_id = sqlalchemy.Column(
        sqlalchemy.Integer, primary_key=True, autoincrement=True
    )
    author_id = sqlalchemy.Column(
        sqlalchemy.Integer,
        sqlalchemy.ForeignKey("bookmetrics.author.author_id", ondelete="CASCADE"),
    )
    book_id = sqlalchemy.Column(
        sqlalchemy.Integer,
        sqlalchemy.ForeignKey("bookmetrics.book.book_id", ondelete="CASCADE"),
    )


author = Author(name="Уильям Шекспир")
book = Book(title="Гамлет", isbn="9780140707342")


def insert_author_book(session):
    session.add(author)
    session.add(book)
    session.commit()
    session.add(AuthorXBook(author_id=author.author_id, book_id=book.book_id))
    session.commit()


def get_all_author_books(session):
    books = (
        session.query(Book.title, Book.isbn, Book.edition)
        .join(AuthorXBook, AuthorXBook.book_id == Book.book_id)
        .join(Author, Author.author_id == AuthorXBook.author_id)
        .filter(Author.name == author.name)
        .all()
    )
    if books:
        print("Книги {}:".format(author.name))
        for book in books:
            print(
                "\t{} - ISBN: {} - Edition: {}".format(
                    book.title, book.isbn, book.edition
                )
            )


def set_edition(session):
    updated_books = session.query(Book).filter(Book.title == book.title)
    updated_books.update(
        {Book.edition: "Зарубежная классика"}, synchronize_session="fetch"
    )
    session.commit()


def delete_records(session):
    deleted_authors = session.query(Author).filter(Author.name == author.name).all()
    for del_author in deleted_authors:
        session.query(AuthorXBook).filter(
            AuthorXBook.author_id == del_author.author_id
        ).delete(synchronize_session="fetch")
        session.delete(del_author)
    session.commit()
    deleted_books = session.query(Book).filter(Book.title == book.title).all()
    for del_book in deleted_books:
        session.query(AuthorXBook).filter(
            AuthorXBook.book_id == del_book.book_id
        ).delete(synchronize_session="fetch")
        session.delete(del_book)
    session.commit()


def make_semantic_analytical_queries(session):
    # вывести для каждого автора количество написанных им книг, составить рейтингов самых "пишущих" авторов
    authors_books_rank = (
        session.query(
            Author.author_id,
            Author.name,
            sqlalchemy.func.count(Book.book_id).label("total_books"),
            sqlalchemy.func.dense_rank()
            .over(order_by=sqlalchemy.func.count(Book.book_id).desc())
            .label("rank"),
        )
        .join(AuthorXBook, AuthorXBook.author_id == Author.author_id)
        .join(Book, AuthorXBook.book_id == Book.book_id)
        .group_by(Author.author_id, Author.name)
        .order_by(sqlalchemy.sql.expression.asc("rank"))
        .all()
    )
    for author in authors_books_rank:
        print(
            f"Автор: {author.name}, Количество книг: {author.total_books}, Место в рейтинге: {author.rank}"
        )


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--login", required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("--db-name", required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    engine = sqlalchemy.create_engine(
        f"postgresql://{args.login}:{args.password}@localhost/{args.db_name}"
    )
    with sqlalchemy.orm.sessionmaker(bind=engine)() as session:
        insert_author_book(session)
        get_all_author_books(session)
        set_edition(session)
        get_all_author_books(session)
        delete_records(session)
        make_semantic_analytical_queries(session)


if __name__ == "__main__":
    main()
