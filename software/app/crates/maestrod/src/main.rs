use std::net::SocketAddr;

use axum::{Router, routing::get};
use tokio::{
    net::TcpListener,
    signal::unix::{SignalKind, signal},
};

const DEFAULT_LISTEN: &str = "[::]:8080";

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let addr: SocketAddr = std::env::var("MAESTRO_LISTEN")
        .unwrap_or_else(|_| DEFAULT_LISTEN.to_owned())
        .parse()
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidInput, e))?;

    let app = Router::new().route("/healthz", get(|| async { "ok" }));

    let listener = TcpListener::bind(addr).await?;
    eprintln!("maestrod listening on {addr}");
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown())
        .await
}

async fn shutdown() {
    let mut term = match signal(SignalKind::terminate()) {
        Ok(term) => term,
        Err(e) => {
            eprintln!("cannot listen for SIGTERM: {e}");
            std::future::pending::<()>().await;
            return;
        }
    };
    tokio::select! {
        _ = term.recv() => {}
        _ = tokio::signal::ctrl_c() => {}
    }
}
