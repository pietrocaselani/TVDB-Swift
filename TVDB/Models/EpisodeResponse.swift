public final class EpisodeResponse: Codable {
  public let episode: FullEpisode

	enum CodingKeys: String, CodingKey {
		case episode = "data"
	}
}
