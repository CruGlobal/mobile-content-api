# frozen_string_literal: true

# Canonical ISO 3166-1 alpha-2 list, stored and compared in lowercase, plus the
# model plumbing that keeps it that way: include this and a model gets the
# presence/inclusion validation and the downcasing callback.
#
# Country is a permission key (see ResourceScorePermission), so an unrecognized
# code is not a harmless typo: "uk" instead of "gb" silently produces a grant
# that can never match a score, and a score that no grant can ever reach. And
# because ResourceScorePolicy matches grants to scores by exact string equality,
# both sides have to agree on what a valid, normalized country looks like --
# hence one shared implementation rather than a copy per model.
module CountryCodes
  extend ActiveSupport::Concern

  ALPHA2 = %w[
    ad ae af ag ai al am ao aq ar as at au aw ax az
    ba bb bd be bf bg bh bi bj bl bm bn bo bq br bs bt bv bw by bz
    ca cc cd cf cg ch ci ck cl cm cn co cr cu cv cw cx cy cz
    de dj dk dm do dz
    ec ee eg eh er es et
    fi fj fk fm fo fr
    ga gb gd ge gf gg gh gi gl gm gn gp gq gr gs gt gu gw gy
    hk hm hn hr ht hu
    id ie il im in io iq ir is it
    je jm jo jp
    ke kg kh ki km kn kp kr kw ky kz
    la lb lc li lk lr ls lt lu lv ly
    ma mc md me mf mg mh mk ml mm mn mo mp mq mr ms mt mu mv mw mx my mz
    na nc ne nf ng ni nl no np nr nu nz
    om
    pa pe pf pg ph pk pl pm pn pr ps pt pw py
    qa
    re ro rs ru rw
    sa sb sc sd se sg sh si sj sk sl sm sn so sr ss st sv sx sy sz
    tc td tf tg th tj tk tl tm tn to tr tt tv tw tz
    ua ug um us uy uz
    va vc ve vg vi vn vu
    wf ws
    ye yt
    za zm zw
  ].to_set.freeze

  INVALID_MESSAGE = "is not a recognized ISO 3166-1 alpha-2 country code"

  included do
    validates :country, presence: true, inclusion: {in: ALPHA2, message: INVALID_MESSAGE}

    before_validation :downcase_country
  end

  def self.valid?(code)
    ALPHA2.include?(code.to_s.downcase)
  end

  private

  def downcase_country
    self.country = country.downcase if country.present?
  end
end
