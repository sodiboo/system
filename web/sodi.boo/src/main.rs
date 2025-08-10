use std::fs;

use atom_syndication::{
    EntryBuilder, FeedBuilder, GeneratorBuilder, LinkBuilder, PersonBuilder, Text, WriteConfig,
};
use chrono::DateTime;
use const_format::concatcp;
use webpage::HTML;

// should not be a URL but too late to change lol
const BLOG_ID: &str = "https://sodi.boo/blog";

const BASE_URL: &str = "https://sodi.boo";
const BLOG: &str = "/blog/";
const FEED: &str = "/blog/feed.atom";

const HOME: &str = BASE_URL;
const BLOG_URL: &str = concatcp!(BASE_URL, BLOG);
const FEED_URL: &str = concatcp!(BASE_URL, FEED);

const BLOG_PATH: &str = concatcp!(".", BLOG);
const FEED_PATH: &str = concatcp!(".", FEED);

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let sodiboo = PersonBuilder::default()
        .name("sodiboo")
        .uri(Some(HOME.into()))
        .build();

    let mut feed = FeedBuilder::default();

    feed.title("sodiboo's infodumping garden")
        .id(BLOG_ID)
        .generator(Some(
            GeneratorBuilder::default()
                .value("custom; written in Rust; based on opengraph attributes")
                .build(),
        ))
        .link(
            LinkBuilder::default()
                .href(BLOG_URL)
                .mime_type(Some("text/html".into()))
                .build(),
        )
        .link(
            LinkBuilder::default()
                .href(FEED_URL)
                .rel("self")
                .mime_type(Some("application/atom+xml".into()))
                .build(),
        )
        .author(sodiboo.clone());

    let mut last_updated = None;

    for article in fs::read_dir(BLOG_PATH)? {
        let article = article?;
        if !article.file_type()?.is_file() {
            eprintln!("skipping {:?} because it's not a file", article.path());
            continue;
        }

        if article.path().extension() != Some("html".as_ref()) {
            eprintln!(
                "skipping {:?} because it's not an HTML file",
                article.path()
            );
            continue;
        }

        let page = HTML::from_file(
            article.path().to_str().expect("the path should be UTF-8"),
            None,
        )?;

        if page.opengraph.og_type != "article" {
            eprintln!("skipping {:?} because it's not an article", article.path());
            continue;
        }

        macro_rules! time {
            ($key:literal) => {
                page.meta
                    .get($key)
                    .map(String::as_str)
                    .map(DateTime::parse_from_rfc3339)
                    .transpose()
            };
        }

        let published = time!("og:article:published_time")?;
        let updated = time!("og:article:modified_time")?
            .or(published)
            .expect("published or modified time should be present");

        last_updated = last_updated.max(Some(updated));

        let url = page.meta.get("og:url").expect("og:url should be present");
        let title = page
            .meta
            .get("og:title")
            .expect("og:title should be present");

        feed.entry(
            EntryBuilder::default()
                .title(Text::plain(title))
                .id(url)
                .published(published)
                .updated(updated)
                .link(
                    LinkBuilder::default()
                        .href(url)
                        .title(Some(title.into()))
                        .mime_type(Some("text/html".into()))
                        .build(),
                )
                .author(sodiboo.clone())
                .build(),
        );
    }

    feed.updated(last_updated.expect("at least one article should be present"));

    feed.build().write_with_config(
        std::fs::File::create(FEED_PATH)?,
        WriteConfig {
            write_document_declaration: false,
            indent_size: Some(2),
        },
    )?;

    Ok(())
}
