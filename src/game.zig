const Game = struct {
  height: i32 = 9,
  width: i32 = 9,
  per: f64 = 1,
  
  pub fn new (
    self: *const Game,
    height: i32,
    width: i32,
  ) *Game {
    return self.set_height(height)
      .set_width(width)
      .calc_per();
  }

  fn set_height(self: *const Game, height: i32) *Game {
    self.height = height;

    if (self.height < 6) {
      self.height = 6;
    }

    return self;
  }

  fn set_width(self: *const Game, width: i32) *Game {
    self.width = width;

    if (self.width < 6) {
      self.width = 6;
    }

    return self;
  }

  fn calc_per(self: *const Game) *Game {
    var per: f64 = 6;
    const height: *const i32 = self.height;
    const width: *const i32 = self.width;

    if (height > width) {
      if (height / width >= 20) {
        per -= 1;
      }

      if (height / width >= 100) {
        per -= 1;
      }
    } else {
      if (width / height >= 20) {
        per -= 1;
      }

      if (width / height >= 100) {
        per -= 1;
      }
    }

    self.per = per;

    return self;
  }
};
