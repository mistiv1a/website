#let doc-template(
    title: "TITLE",
    date: "1970-01-01",
    body: ""
) = [
    #show link: it => underline(
        offset: 2pt,
        stroke: 0.5pt,
        extent: 1pt,
        it
    )
    #show raw.where(block: true): block.with(
        inset: (left: 24pt, top: 0em, bottom: 0em),
        width: 100%
    )
    #show raw: set text(font: (
        "Sarasa Mono SC"
    ))
    #show raw.where(block: true): set text(
        size: 0.8em,
    )
    #set text(font: (
        "Libertinus Serif",
        "FZNewShuSong-Z10S",
    ))
    #set heading(numbering: "1.")
    #set page(
        paper: "a5",
        number-align: center,
    )
    #set page(numbering: "1")
    #set page(
        footer: context {
            set text(
                font: "Libertinus Serif",
                size: 0.7em,
                weight: "bold"
            )
            align(center, counter(page).display())
        }
    )
    #counter(page).update(1)
    #align(center, text(27pt, font: "Source Han Serif", weight: "medium")[
        *#title*
    ])
    #show heading: set text(font: "Source Han Serif", weight: "semibold")
    #align(center, [#par(first-line-indent: 0em)[#date] #v(0.5em)])
    #set par(
        first-line-indent: 2em,
        justify: true,
        leading: 0.8em,
        spacing: 0.8em,
    )
    #set list(indent: 23pt)
    #set enum(indent: 23pt)
    #set terms(indent: 23pt)
    #show heading: it =>  {
        par(leading:0pt,spacing:0pt)[#text(size:0pt)[]]
        it
        par(leading:0pt,spacing:0pt)[#text(size:0pt)[]]
    }

    #let list-depth = state("list-depth", 0)
    #show list: it => {
        list-depth.update(d => d + 1)
        context {
            if list-depth.get() == 1 {
                par(leading: 0pt, spacing: 0pt)[#text(size: 0pt)[]]
                it
                par(leading: 0pt, spacing: 0pt)[#text(size: 0pt)[]]
            } else {
                it
            }
        }
        list-depth.update(d => d - 1)
    }
    
    #show raw.where(block: true): it => {
        par(leading:0pt,spacing:0pt)[#text(size:0pt)[]]
        it
        par(leading:0pt,spacing:0pt)[#text(size:0pt)[]]
    }
    #show image: it => { align(center)[ #it ] }
    #show image: it => {
        par(leading:0pt,spacing:0pt)[#text(size:0pt)[]]
        it
        par(leading:0pt,spacing:0pt)[#text(size:0pt)[]]
    }
    #show math.equation: it => {
        if it.block {
            par(leading: 0pt, spacing: 0pt)[#text(size: 0pt)[]]
            it
            par(leading: 0pt, spacing: 0pt)[#text(size: 0pt)[]]
        } else {
            it
        }
    }
    #set math.equation(numbering: "(1)")
    #body
]

#let myquote(body) = {
    par(leading:0pt,spacing:0pt)[#text(size:0pt)[]]
    pad(left: 2em, block(
        stroke: (left: 3pt + gray),
        inset: (left: 10pt, rest: 5pt),
        fill: luma(250),
    )[#body])
    par(leading:0pt,spacing:0pt)[#text(size:0pt)[]]
}
