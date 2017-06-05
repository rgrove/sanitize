# encoding: utf-8

class Sanitize
  module Config
    RELAXED = freeze_config(
      :elements => BASIC[:elements] + %w[
        address article aside bdi bdo body caption col colgroup data del div
        figcaption figure footer h1 h2 h3 h4 h5 h6 head header hgroup hr html
        img ins main nav rp rt ruby section span style summary sup table tbody
        td tfoot th thead title tr wbr
      ],

      :allow_doctype => true,

      :attributes => merge(BASIC[:attributes],
        :all       => %w[class dir hidden id lang style tabindex title translate],
        'a'        => %w[href hreflang name rel],
        'col'      => %w[span width],
        'colgroup' => %w[span width],
        'data'     => %w[value],
        'del'      => %w[cite datetime],
        'img'      => %w[align alt border height src srcset width],
        'ins'      => %w[cite datetime],
        'li'       => %w[value],
        'ol'       => %w[reversed start type],
        'style'    => %w[media scoped type],
        'table'    => %w[align bgcolor border cellpadding cellspacing frame rules sortable summary width],
        'td'       => %w[abbr align axis colspan headers rowspan valign width],
        'th'       => %w[abbr align axis colspan headers rowspan scope sorted valign width],
        'ul'       => %w[type]
      ),

      :protocols => merge(BASIC[:protocols],
        'del' => {'cite' => ['http', 'https', :relative]},
        'img' => {'src'  => ['http', 'https', 'data', :relative]},
        'ins' => {'cite' => ['http', 'https', :relative]}
      ),

      :css => {
        :allow_comments => true,
        :allow_hacks    => true,

        :at_rules_with_properties => %w[
          bottom-center
          bottom-left
          bottom-left-corner
          bottom-right
          bottom-right-corner
          font-face
          left-bottom
          left-middle
          left-top
          page
          right-bottom
          right-middle
          right-top
          top-center
          top-left
          top-left-corner
          top-right
          top-right-corner
        ],

        :at_rules_with_styles => %w[
          -moz-keyframes
          -o-keyframes
          -webkit-keyframes
          document
          keyframes
          media
          supports
        ],

        :protocols => ['http', 'https', :relative],

        :properties => %w[
          -moz-appearance
          -moz-background-inline-policy
          -moz-box-sizing
          -moz-column-count
          -moz-column-fill
          -moz-column-gap
          -moz-column-rule
          -moz-column-rule-color
          -moz-column-rule-style
          -moz-column-rule-width
          -moz-column-width
          -moz-font-feature-settings
          -moz-font-language-override
          -moz-hyphens
          -moz-text-align-last
          -moz-text-decoration-color
          -moz-text-decoration-line
          -moz-text-decoration-style
          -moz-text-size-adjust
          -ms-background-position-x
          -ms-background-position-y
          -ms-block-progression
          -ms-content-zoom-chaining
          -ms-content-zoom-limit
          -ms-content-zoom-limit-max
          -ms-content-zoom-limit-min
          -ms-content-zoom-snap
          -ms-content-zoom-snap-points
          -ms-content-zoom-snap-type
          -ms-content-zooming
          -ms-filter
          -ms-flex
          -ms-flex-align
          -ms-flex-direction
          -ms-flex-order
          -ms-flex-pack
          -ms-flex-wrap
          -ms-flow-from
          -ms-flow-into
          -ms-grid-column
          -ms-grid-column-align
          -ms-grid-column-span
          -ms-grid-columns
          -ms-grid-row
          -ms-grid-row-align
          -ms-grid-row-span
          -ms-grid-rows
          -ms-high-contrast-adjust
          -ms-hyphenate-limit-chars
          -ms-hyphenate-limit-lines
          -ms-hyphenate-limit-zone
          -ms-hyphens
          -ms-ime-mode
          -ms-interpolation-mode
          -ms-layout-flow
          -ms-layout-grid
          -ms-layout-grid-char
          -ms-layout-grid-line
          -ms-layout-grid-mode
          -ms-layout-grid-type
          -ms-overflow-style
          -ms-overflow-x
          -ms-overflow-y
          -ms-progress-appearance
          -ms-scroll-chaining
          -ms-scroll-limit
          -ms-scroll-limit-x-max
          -ms-scroll-limit-x-min
          -ms-scroll-limit-y-max
          -ms-scroll-limit-y-min
          -ms-scroll-rails
          -ms-scroll-snap-points-x
          -ms-scroll-snap-points-y
          -ms-scroll-snap-type
          -ms-scroll-snap-x
          -ms-scroll-snap-y
          -ms-scroll-translation
          -ms-scrollbar-arrow-color
          -ms-scrollbar-base-color
          -ms-scrollbar-darkshadow-color
          -ms-scrollbar-face-color
          -ms-scrollbar-highlight-color
          -ms-scrollbar-shadow-color
          -ms-scrollbar-track-color
          -ms-text-align-last
          -ms-text-autospace
          -ms-text-justify
          -ms-text-kashida-space
          -ms-text-overflow
          -ms-text-size-adjust
          -ms-text-underline-position
          -ms-touch-action
          -ms-user-select
          -ms-word-break
          -ms-word-wrap
          -ms-wrap-flow
          -ms-wrap-margin
          -ms-wrap-through
          -ms-writing-mode
          -ms-zoom
          -webkit-align-content
          -webkit-align-items
          -webkit-align-self
          -webkit-animation
          -webkit-animation-delay
          -webkit-animation-direction
          -webkit-animation-duration
          -webkit-animation-fill-mode
          -webkit-animation-iteration-count
          -webkit-animation-name
          -webkit-animation-play-state
          -webkit-animation-timing-function
          -webkit-appearance
          -webkit-backface-visibility
          -webkit-background-blend-mode
          -webkit-background-clip
          -webkit-background-composite
          -webkit-background-origin
          -webkit-background-size
          -webkit-blend-mode
          -webkit-border-after
          -webkit-border-after-color
          -webkit-border-after-style
          -webkit-border-after-width
          -webkit-border-before
          -webkit-border-before-color
          -webkit-border-before-style
          -webkit-border-before-width
          -webkit-border-bottom-left-radius
          -webkit-border-bottom-right-radius
          -webkit-border-end
          -webkit-border-end-color
          -webkit-border-end-style
          -webkit-border-end-width
          -webkit-border-fit
          -webkit-border-image
          -webkit-border-radius
          -webkit-border-start
          -webkit-border-start-color
          -webkit-border-start-style
          -webkit-border-start-width
          -webkit-border-top-left-radius
          -webkit-border-top-right-radius
          -webkit-box-align
          -webkit-box-decoration-break
          -webkit-box-flex
          -webkit-box-flex-group
          -webkit-box-lines
          -webkit-box-ordinal-group
          -webkit-box-orient
          -webkit-box-pack
          -webkit-box-reflect
          -webkit-box-shadow
          -webkit-box-sizing
          -webkit-clip-path
          -webkit-column-axis
          -webkit-column-break-after
          -webkit-column-break-before
          -webkit-column-break-inside
          -webkit-column-count
          -webkit-column-gap
          -webkit-column-progression
          -webkit-column-rule
          -webkit-column-rule-color
          -webkit-column-rule-style
          -webkit-column-rule-width
          -webkit-column-span
          -webkit-column-width
          -webkit-columns
          -webkit-filter
          -webkit-flex
          -webkit-flex-basis
          -webkit-flex-direction
          -webkit-flex-flow
          -webkit-flex-grow
          -webkit-flex-shrink
          -webkit-flex-wrap
          -webkit-flow-from
          -webkit-flow-into
          -webkit-font-size-delta
          -webkit-font-smoothing
          -webkit-grid-area
          -webkit-grid-auto-columns
          -webkit-grid-auto-flow
          -webkit-grid-auto-rows
          -webkit-grid-column
          -webkit-grid-column-end
          -webkit-grid-column-start
          -webkit-grid-definition-columns
          -webkit-grid-definition-rows
          -webkit-grid-row
          -webkit-grid-row-end
          -webkit-grid-row-start
          -webkit-justify-content
          -webkit-line-clamp
          -webkit-logical-height
          -webkit-logical-width
          -webkit-margin-after
          -webkit-margin-after-collapse
          -webkit-margin-before
          -webkit-margin-before-collapse
          -webkit-margin-bottom-collapse
          -webkit-margin-collapse
          -webkit-margin-end
          -webkit-margin-start
          -webkit-margin-top-collapse
          -webkit-marquee
          -webkit-marquee-direction
          -webkit-marquee-increment
          -webkit-marquee-repetition
          -webkit-marquee-speed
          -webkit-marquee-style
          -webkit-mask
          -webkit-mask-box-image
          -webkit-mask-box-image-outset
          -webkit-mask-box-image-repeat
          -webkit-mask-box-image-slice
          -webkit-mask-box-image-source
          -webkit-mask-box-image-width
          -webkit-mask-clip
          -webkit-mask-composite
          -webkit-mask-image
          -webkit-mask-origin
          -webkit-mask-position
          -webkit-mask-position-x
          -webkit-mask-position-y
          -webkit-mask-repeat
          -webkit-mask-repeat-x
          -webkit-mask-repeat-y
          -webkit-mask-size
          -webkit-mask-source-type
          -webkit-max-logical-height
          -webkit-max-logical-width
          -webkit-min-logical-height
          -webkit-min-logical-width
          -webkit-opacity
          -webkit-order
          -webkit-padding-after
          -webkit-padding-before
          -webkit-padding-end
          -webkit-padding-start
          -webkit-perspective
          -webkit-perspective-origin
          -webkit-perspective-origin-x
          -webkit-perspective-origin-y
          -webkit-region-break-after
          -webkit-region-break-before
          -webkit-region-break-inside
          -webkit-region-fragment
          -webkit-shape-inside
          -webkit-shape-margin
          -webkit-shape-outside
          -webkit-shape-padding
          -webkit-svg-shadow
          -webkit-tap-highlight-color
          -webkit-text-decoration
          -webkit-text-decoration-color
          -webkit-text-decoration-line
          -webkit-text-decoration-style
          -webkit-text-size-adjust
          -webkit-touch-callout
          -webkit-transform
          -webkit-transform-origin
          -webkit-transform-origin-x
          -webkit-transform-origin-y
          -webkit-transform-origin-z
          -webkit-transform-style
          -webkit-transition
          -webkit-transition-delay
          -webkit-transition-duration
          -webkit-transition-property
          -webkit-transition-timing-function
          -webkit-user-drag
          -webkit-wrap-flow
          -webkit-wrap-through
          align-content
          align-items
          align-self
          alignment-adjust
          alignment-baseline
          all
          anchor-point
          animation
          animation-delay
          animation-direction
          animation-duration
          animation-fill-mode
          animation-iteration-count
          animation-name
          animation-play-state
          animation-timing-function
          azimuth
          backface-visibility
          background
          background-attachment
          background-clip
          background-color
          background-image
          background-origin
          background-position
          background-repeat
          background-size
          baseline-shift
          binding
          bleed
          bookmark-label
          bookmark-level
          bookmark-state
          border
          border-bottom
          border-bottom-color
          border-bottom-left-radius
          border-bottom-right-radius
          border-bottom-style
          border-bottom-width
          border-collapse
          border-color
          border-image
          border-image-outset
          border-image-repeat
          border-image-slice
          border-image-source
          border-image-width
          border-left
          border-left-color
          border-left-style
          border-left-width
          border-radius
          border-right
          border-right-color
          border-right-style
          border-right-width
          border-spacing
          border-style
          border-top
          border-top-color
          border-top-left-radius
          border-top-right-radius
          border-top-style
          border-top-width
          border-width
          bottom
          box-decoration-break
          box-shadow
          box-sizing
          box-snap
          box-suppress
          break-after
          break-before
          break-inside
          caption-side
          chains
          clear
          clip
          clip-path
          clip-rule
          color
          color-interpolation
          color-interpolation-filters
          color-profile
          color-rendering
          column-count
          column-fill
          column-gap
          column-rule
          column-rule-color
          column-rule-style
          column-rule-width
          column-span
          column-width
          columns
          contain
          content
          counter-increment
          counter-reset
          counter-set
          crop
          cue
          cue-after
          cue-before
          cursor
          direction
          display
          display-inside
          display-list
          display-outside
          dominant-baseline
          elevation
          empty-cells
          enable-background
          fill
          fill-opacity
          fill-rule
          filter
          flex
          flex-basis
          flex-direction
          flex-flow
          flex-grow
          flex-shrink
          flex-wrap
          float
          float-offset
          flood-color
          flood-opacity
          flow-from
          flow-into
          font
          font-family
          font-feature-settings
          font-kerning
          font-language-override
          font-size
          font-size-adjust
          font-stretch
          font-style
          font-synthesis
          font-variant
          font-variant-alternates
          font-variant-caps
          font-variant-east-asian
          font-variant-ligatures
          font-variant-numeric
          font-variant-position
          font-weight
          glyph-orientation-horizontal
          glyph-orientation-vertical
          grid
          grid-area
          grid-auto-columns
          grid-auto-flow
          grid-auto-rows
          grid-column
          grid-column-end
          grid-column-start
          grid-row
          grid-row-end
          grid-row-start
          grid-template
          grid-template-areas
          grid-template-columns
          grid-template-rows
          hanging-punctuation
          height
          hyphens
          icon
          image-orientation
          image-rendering
          image-resolution
          ime-mode
          initial-letters
          inline-box-align
          justify-content
          justify-items
          justify-self
          kerning
          left
          letter-spacing
          lighting-color
          line-box-contain
          line-break
          line-grid
          line-height
          line-snap
          line-stacking
          line-stacking-ruby
          line-stacking-shift
          line-stacking-strategy
          list-style
          list-style-image
          list-style-position
          list-style-type
          margin
          margin-bottom
          margin-left
          margin-right
          margin-top
          marker
          marker-end
          marker-mid
          marker-offset
          marker-side
          marker-start
          marks
          mask
          mask-box
          mask-box-outset
          mask-box-repeat
          mask-box-slice
          mask-box-source
          mask-box-width
          mask-clip
          mask-image
          mask-origin
          mask-position
          mask-repeat
          mask-size
          mask-source-type
          mask-type
          max-height
          max-lines
          max-width
          min-height
          min-width
          move-to
          nav-down
          nav-index
          nav-left
          nav-right
          nav-up
          object-fit
          object-position
          opacity
          order
          orphans
          outline
          outline-color
          outline-offset
          outline-style
          outline-width
          overflow
          overflow-wrap
          overflow-x
          overflow-y
          padding
          padding-bottom
          padding-left
          padding-right
          padding-top
          page
          page-break-after
          page-break-before
          page-break-inside
          page-policy
          pause
          pause-after
          pause-before
          perspective
          perspective-origin
          pitch
          pitch-range
          play-during
          pointer-events
          position
          presentation-level
          quotes
          region-fragment
          resize
          rest
          rest-after
          rest-before
          richness
          right
          rotation
          rotation-point
          ruby-align
          ruby-merge
          ruby-position
          shape-image-threshold
          shape-margin
          shape-outside
          shape-rendering
          size
          speak
          speak-as
          speak-header
          speak-numeral
          speak-punctuation
          speech-rate
          stop-color
          stop-opacity
          stress
          string-set
          stroke
          stroke-dasharray
          stroke-dashoffset
          stroke-linecap
          stroke-linejoin
          stroke-miterlimit
          stroke-opacity
          stroke-width
          tab-size
          table-layout
          text-align
          text-align-last
          text-anchor
          text-combine-horizontal
          text-combine-upright
          text-decoration
          text-decoration-color
          text-decoration-line
          text-decoration-skip
          text-decoration-style
          text-emphasis
          text-emphasis-color
          text-emphasis-position
          text-emphasis-style
          text-height
          text-indent
          text-justify
          text-orientation
          text-overflow
          text-rendering
          text-shadow
          text-size-adjust
          text-space-collapse
          text-transform
          text-underline-position
          text-wrap
          top
          touch-action
          transform
          transform-origin
          transform-style
          transition
          transition-delay
          transition-duration
          transition-property
          transition-timing-function
          unicode-bidi
          unicode-range
          vertical-align
          visibility
          voice-balance
          voice-duration
          voice-family
          voice-pitch
          voice-range
          voice-rate
          voice-stress
          voice-volume
          volume
          white-space
          widows
          width
          will-change
          word-break
          word-spacing
          word-wrap
          wrap-flow
          wrap-through
          writing-mode
          z-index
        ]
      }
    )
  end
end
