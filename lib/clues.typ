// gentle-clues
#import "@preview/linguify:0.4.0": *

// Helper
#let if-auto-then(val,ret) = {
  if (val == auto){
    ret
  } else {
    val
  }
}

// Global states
#let __gc_clues_breakable = state("breakable", false)
#let __gc_clues_headless = state("headless", false)
#let __gc_clue_width = state("clue-width", auto)
#let __gc_header_inset = state("header-inset", 0.5em)
#let __gc_content_inset = state("content-inset", 1em)
#let __gc_border_radius = state("border-radius", 2pt)
#let __gc_border_width = state("border-width", 0.5pt)
#let __gc_stroke_width = state("stroke-width", 2pt)

#let __gc_task-counter = counter("gc-task-counter")
#let __gc_enable-task-counter = state("gc-task-counter", true)

// load linguify language database
#let lang_database = toml("lang.toml")

/// Config Init
#let gentle-clues(
  breakable: false,
  headless: false,
  header-inset: 0.5em,
  // default-title: auto, // string or none
  // default-icon: emoji.magnify.l, // file or symbol
  // default-color: navy, // color profile name
  width: auto, // length
  stroke-width: 2pt,
  border-radius: 2pt, // length
  border-width: 0.5pt, // length
  content-inset: 1em, // length
  show-task-counter: false, // [bool]
  body
) = {
  // Conf linguify to lang parameter
  // linguify_set_database(toml("lang.toml"));

  // Update breakability
  __gc_clues_breakable.update(breakable);

  // Update clues width
  __gc_clue_width.update(width);

  // Update headless state
  __gc_clues_headless.update(headless);

  // Update header inset
  __gc_header_inset.update(header-inset);

  // Update border radius
  __gc_border_radius.update(border-radius);

  // Update border width
  __gc_border_width.update(border-width);

  // Update stroke width
  __gc_stroke_width.update(stroke-width);

  // Update content inset
  __gc_content_inset.update(content-inset);

  // Update if task counter should be shown
  __gc_enable-task-counter.update(show-task-counter);

  body

  }

// Basic gentle-clue (clue) template
#let clue(
  content,
  title: "", // string or none
  icon: emoji.magnify.l, // file or symbol
  accent-color: navy, // color
  border-color: auto,
  header-color: auto,
  body-color: none,
  width: auto, // length
  radius: auto, // length
  border-width: auto, // length
  content-inset: auto, // length
  header-inset: auto, // length
  breakable: auto,
) = {
  context {
    // Set default color:
    let _stroke-color = luma(70);
    let _header-color = _stroke-color.lighten(85%);
    let _border-color = _header-color.darken(10%);
    let _border-width = if-auto-then(border-width, __gc_border_width.get());
    let _border-radius = if-auto-then(radius, __gc_border_radius.get())
    let _stroke-width = if-auto-then(auto, __gc_stroke_width.get())
    let _clip-content = true

    // check color types
    assert(type(accent-color) in (color, gradient, pattern), message: "expected color, gradient or pattern found " + type(accent-color));

    if (header-color != auto) {
      assert(type(header-color) in (color, gradient, pattern), message: "expected color, gradient or pattern found " + type(header-color));
    }
    if (border-color != auto) {
      assert(type(border-color) in (color, gradient, pattern), message: "expected color, gradient or pattern, found " + type(border-color));
    }
    if (body-color != none) {
      assert(type(body-color) in (color, gradient, pattern), message: "expected color, gradient or pattern, found " + type(body-color));
    }

    // setting bg and stroke color from color argument
    if (type(accent-color) == color) {
      _stroke-color = accent-color;
      _header-color = if-auto-then(header-color, accent-color.lighten(85%));
      _border-color = if-auto-then(border-color, accent-color.lighten(70%));
    } else if (type(accent-color) == gradient) {
      _stroke-color = accent-color
      _header-color = if-auto-then(header-color, accent-color);
      _border-color = if-auto-then(border-color, accent-color);
    }


    // Disable Heading numbering for those headings
    set heading(numbering: none, outlined: false, supplement: "Box")

    // Header Part
    let header = box(
            fill: _header-color,
            width: 100%,
            radius: (top-right: _border-radius),
            inset: if-auto-then(header-inset, __gc_header_inset.get()),
            stroke: (right: _border-width + _header-color )
          )[
              #if icon == none { strong(title) } else {
                grid(
                  columns: (auto, auto),
                  align: (horizon, left + horizon),
                  gutter: 1em,
                  box(height: 1em)[
                    #if type(icon) == symbol {
                        text(1em,icon)
                    } else {
                      image(icon, fit: "contain")
                    }
                  ],
                  strong(title)
                )
              }
          ]

    // Content-Box
    let content-box(content) = block(
      breakable: if-auto-then(breakable, __gc_clues_breakable.get()),
      width: 100%,
      fill: body-color,
      inset: if-auto-then(content-inset, __gc_content_inset.get()),
      radius: (
        top-left: 0pt,
        bottom-left: 0pt,
        top-right: if (title != none){0pt} else {_border-radius},
        rest: _border-radius
      ),
    )[#content]

    // Wrapper-Block
    block(
      breakable: if-auto-then(breakable, __gc_clues_breakable.get()),
      width: if-auto-then(width, __gc_clue_width.get()),
      inset: (left: 1pt),
      radius: (right: _border-radius, left: 0pt),
      stroke: (
        left: (thickness: _stroke-width, paint: _stroke-color, cap: "butt"),
        top: if (title != none){_border-width + _header-color} else {_border-width + _border-color},
        rest: _border-width + _border-color,
      ),
      clip: _clip-content,
    )[
      #set align(start)
      #stack(dir: ttb,
        if __gc_clues_headless.get() == false and title != none {
          header
        },
        content-box(content)
      )
    ] // block end
  }
}

#let increment_task_counter() = {
    context {
    if (__gc_enable-task-counter.get() == true){
      __gc_task-counter.step()
    }
  }
}

#let get_task_number() = {
  context {
    if (__gc_enable-task-counter.get() == true){
      " " + __gc_task-counter.display()
    }
  }
}

// Helper for fetching the translated title
#let get-title-for(clue) = {
  assert.eq(type(clue),str);
  return linguify(clue, from: lang_database, default: linguify(clue, lang: "en", default: clue));
}
