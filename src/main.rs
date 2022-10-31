use sqlx::{Connection, PgConnection};
use uuid::Uuid;

pub struct DBSettings {
    pub user: String,
    pub password: String,
    pub port: u16,
    pub host: String,
    pub database_name: String,
}

impl DBSettings {
    pub fn connection_string(&self) -> String {
        format!(
            "postgres://{}:{}@{}:{}/{}",
            self.user, self.password, self.host, self.port, self.database_name,
        )
    }
}

#[tokio::main]
async fn main() {
    let db_settings = DBSettings {
        user: String::from("postgres"),
        password: String::from("password"),
        port: 5432,
        host: String::from("localhost"),
        database_name: String::from("mynewdb"),
    };

    let connection_string = db_settings.connection_string();
    println!("connection_string: {}", connection_string);
    let mut connection = PgConnection::connect(&connection_string)
        .await
        .expect("failed to connect to Postgres");

    let id = Uuid::new_v4();
    println!("id: {}", id);

    sqlx::query!(
        r#"
        insert into users (id, name) values ($1, $2)
        "#,
        id,
        String::from("Alice"),
    )
    .execute(&mut connection)
    .await
    .expect("failed to insert into users");

    let users = sqlx::query!("select * from users",)
        .fetch_one(&mut connection)
        .await
        .expect("failed to fetch users");

    println!("{:?}", users);

    println!("done");
}
