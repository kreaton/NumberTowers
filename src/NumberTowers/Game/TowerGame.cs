namespace NumberTowers.Game;

public enum BrickColor { Blue, Red, Green, Yellow }

public sealed record Brick(int Id, BrickColor Color, int Number);

/// <summary>
/// Rules for Number Towers: build four colored towers from 1 to 10 using bricks
/// picked from a 4x4 grid. The grid always contains at least one playable brick.
/// </summary>
public sealed class TowerGame
{
    public const int Floors = 10;
    public const int GridSize = 16;

    /// <summary>Wrong picks allowed in a row; the next one knocks a floor off every tower.</summary>
    public const int MaxMisses = 3;

    public static readonly IReadOnlyList<BrickColor> Colors = Enum.GetValues<BrickColor>();

    private readonly Random _rng;
    private readonly Dictionary<BrickColor, int> _heights = new();
    private readonly Brick[] _grid = new Brick[GridSize];
    private int _nextId;

    public TowerGame(Random? rng = null)
    {
        _rng = rng ?? Random.Shared;
        foreach (var color in Colors)
            _heights[color] = 0;
        Shuffle();
    }

    public IReadOnlyList<Brick> Grid => _grid;

    public int HeightOf(BrickColor color) => _heights[color];

    public bool IsComplete(BrickColor color) => _heights[color] >= Floors;

    public bool IsWon => Colors.All(IsComplete);

    public bool HasPlayableBrick => _grid.Any(CanPlace);

    /// <summary>Wrong picks since the last brick that fit.</summary>
    public int Misses { get; private set; }

    public int MissesLeft => Math.Max(0, MaxMisses - Misses);

    public bool CanPlace(Brick brick) =>
        !IsComplete(brick.Color) && brick.Number == _heights[brick.Color] + 1;

    /// <summary>
    /// Tries to lay the brick at <paramref name="index"/> on its tower. On success the
    /// brick is replaced by a new random one. The caller should <see cref="Shuffle"/>
    /// when <see cref="HasPlayableBrick"/> is false afterwards.
    /// </summary>
    public bool TryPlace(int index)
    {
        var brick = _grid[index];
        if (!CanPlace(brick))
        {
            Misses++;
            return false;
        }

        Misses = 0;
        _heights[brick.Color]++;
        if (!IsWon)
            _grid[index] = RandomBrick(index);
        return true;
    }

    /// <summary>True once the player has guessed wrong more than <see cref="MaxMisses"/> times in a row.</summary>
    public bool MissLimitExceeded => Misses > MaxMisses;

    /// <summary>
    /// The penalty for guessing: removes the top floor of every tower and resets the miss count.
    /// The caller should <see cref="Shuffle"/> when <see cref="HasPlayableBrick"/> is false afterwards.
    /// </summary>
    public void LowerTowers()
    {
        foreach (var color in Colors)
            _heights[color] = Math.Max(0, _heights[color] - 1);
        Misses = 0;
    }

    /// <summary>Rebuilds the whole grid, guaranteeing at least one playable brick.</summary>
    public void Shuffle()
    {
        Array.Clear(_grid);
        for (int i = 0; i < GridSize; i++)
            _grid[i] = RandomBrick(i);

        if (!IsWon && !HasPlayableBrick)
        {
            var open = Colors.Where(c => !IsComplete(c)).ToArray();
            var color = open[_rng.Next(open.Length)];
            _grid[_rng.Next(GridSize)] = new Brick(_nextId++, color, _heights[color] + 1);
        }
    }

    /// <summary>
    /// Picks a random brick for slot <paramref name="index"/>, preferring a color and number
    /// that don't already appear elsewhere in the grid.
    /// </summary>
    private Brick RandomBrick(int index)
    {
        var counts = _grid
            .Where((b, i) => i != index && b is not null)
            .CountBy(b => (b.Color, b.Number))
            .ToDictionary();

        // Only use colors of towers that still need bricks, so finished towers don't clutter the grid.
        var open = Colors.Where(c => !IsComplete(c)).ToArray();
        if (open.Length == 0)
            open = Colors.ToArray();

        // With one open tower there are fewer unique bricks than grid slots, so some must repeat;
        // pick from the least-used bricks to keep repeats as few and as spread out as possible.
        var pairs = open
            .SelectMany(c => Enumerable.Range(1, Floors).Select(n => (Color: c, Number: n)))
            .ToArray();
        var fewest = pairs.Min(p => counts.GetValueOrDefault(p));
        var candidates = pairs.Where(p => counts.GetValueOrDefault(p) == fewest).ToArray();

        var (color, number) = candidates[_rng.Next(candidates.Length)];
        return new Brick(_nextId++, color, number);
    }
}
