#!/usr/bin/env python3
"""
Image Color Extractor
Extracts colors from images and exports them to CSS files.
"""

import argparse
import sys
from pathlib import Path
from PIL import Image
import numpy as np
from sklearn.cluster import KMeans
import colorsys


def rgb_to_hex(rgb):
    """Convert RGB tuple to hex color code."""
    return '#{:02x}{:02x}{:02x}'.format(int(rgb[0]), int(rgb[1]), int(rgb[2]))


def hex_to_rgb(hex_color):
    """Convert hex color code to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def get_image_colors(image_path, max_colors=256):
    """Load image and extract all pixel colors."""
    try:
        img = Image.open(image_path)
        # Convert to RGB if necessary
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize if image is too large for faster processing
        max_dimension = 500
        if max(img.size) > max_dimension:
            ratio = max_dimension / max(img.size)
            new_size = (int(img.size[0] * ratio), int(img.size[1] * ratio))
            img = img.resize(new_size, Image.Resampling.LANCZOS)
        
        # Get pixel data
        pixels = np.array(img).reshape(-1, 3)
        return pixels
    except Exception as e:
        print(f"Error loading image: {e}", file=sys.stderr)
        sys.exit(1)


def extract_n_common_colors(image_path, n, use_clustering=True):
    """
    Extract N most common distinct colors from an image.
    Uses KMeans clustering to find distinct color groups.
    """
    pixels = get_image_colors(image_path)
    
    if use_clustering:
        # Use KMeans to find distinct color clusters
        # This naturally groups similar colors together
        kmeans = KMeans(n_clusters=min(n, len(pixels)), random_state=42, n_init=10)
        kmeans.fit(pixels)
        
        # Get cluster centers (the representative colors)
        colors = kmeans.cluster_centers_
        
        # Count pixels in each cluster to sort by frequency
        labels = kmeans.labels_
        unique, counts = np.unique(labels, return_counts=True)
        
        # Sort by frequency (most common first)
        sorted_indices = np.argsort(counts)[::-1]
        colors = colors[sorted_indices]
    else:
        # Simple frequency-based approach (less effective for distinct colors)
        # This would require more sophisticated similarity checking
        unique_colors, counts = np.unique(pixels, axis=0, return_counts=True)
        sorted_indices = np.argsort(counts)[::-1]
        colors = unique_colors[sorted_indices][:n]
    
    return [tuple(c) for c in colors.astype(int)]


def color_distance(rgb1, rgb2):
    """Calculate Euclidean distance between two RGB colors."""
    return np.sqrt(sum((c1 - c2) ** 2 for c1, c2 in zip(rgb1, rgb2)))


def extract_color_range_palette(image_path, range_threshold=50, max_palette_size=10):
    """
    Extract the most common color and find all colors within a certain range.
    Creates a palette from those similar colors.
    
    Args:
        image_path: Path to the image
        range_threshold: Maximum color distance to be considered "in range" (0-255*√3 scale)
        max_palette_size: Maximum number of colors to include in the final palette
    
    Returns:
        List of RGB color tuples representing the palette
    """
    pixels = get_image_colors(image_path)
    
    # Get the single most common color using clustering
    main_color_rgb = extract_n_common_colors(image_path, 1)[0]
    
    # Filter pixels that are within the threshold distance of the main color
    main_color_array = np.array(main_color_rgb)
    distances = np.sqrt(np.sum((pixels - main_color_array) ** 2, axis=1))
    similar_pixels = pixels[distances <= range_threshold]
    
    if len(similar_pixels) == 0:
        # Fallback: return just the main color
        return [main_color_rgb]
    
    # Cluster the similar colors to get representative palette colors
    # Use min to avoid clustering more colors than we have samples
    n_clusters = min(max_palette_size, len(similar_pixels))
    
    if n_clusters == 1:
        # If only one cluster, return the average color within range
        avg_color = np.mean(similar_pixels, axis=0)
        return [tuple(avg_color.astype(int))]
    
    # Use KMeans to find representative colors from the similar ones
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    kmeans.fit(similar_pixels)
    
    # Get cluster centers
    palette_colors = kmeans.cluster_centers_
    
    # Sort by frequency (count pixels in each cluster)
    labels = kmeans.labels_
    unique, counts = np.unique(labels, return_counts=True)
    sorted_indices = np.argsort(counts)[::-1]
    palette_colors = palette_colors[sorted_indices]
    
    # Ensure the main color is included (if not already close enough)
    palette_list = [tuple(c.astype(int)) for c in palette_colors]
    
    # Check if main color is already represented
    main_in_palette = any(
        color_distance(main_color_rgb, pal_color) < 5 
        for pal_color in palette_list
    )
    
    if not main_in_palette:
        # Add main color at the beginning
        palette_list.insert(0, main_color_rgb)
    
    return palette_list


def extract_color_with_variations(image_path, num_variations=5):
    """
    Extract the most common color and generate variations.
    Creates lighter and darker shades.
    """
    # Get the single most common color
    main_color_rgb = extract_n_common_colors(image_path, 1)[0]
    
    # Convert to HSV for easier manipulation
    main_color_hsv = colorsys.rgb_to_hsv(
        main_color_rgb[0] / 255.0,
        main_color_rgb[1] / 255.0,
        main_color_rgb[2] / 255.0
    )
    
    variations = [main_color_rgb]  # Start with the main color
    
    # Generate lighter variations (increase value/brightness)
    for i in range(1, (num_variations // 2) + 1):
        factor = 1 + (i * 0.2)  # Increase brightness
        new_v = min(1.0, main_color_hsv[2] * factor)
        new_rgb = colorsys.hsv_to_rgb(main_color_hsv[0], main_color_hsv[1], new_v)
        variations.append(tuple(int(c * 255) for c in new_rgb))
    
    # Generate darker variations (decrease value/brightness)
    for i in range(1, (num_variations // 2) + 1):
        factor = max(0.0, main_color_hsv[2] - (i * 0.2))  # Decrease brightness
        new_rgb = colorsys.hsv_to_rgb(main_color_hsv[0], main_color_hsv[1], factor)
        variations.append(tuple(int(c * 255) for c in new_rgb))
    
    # Sort variations by brightness for logical ordering
    variations.sort(key=lambda rgb: sum(rgb) / 3, reverse=True)
    
    return variations


def export_to_css(colors, output_path, variable_prefix='color'):
    """
    Export colors to a CSS file with CSS variables.
    """
    css_content = ":root {\n"
    
    for i, color in enumerate(colors, start=1):
        hex_color = rgb_to_hex(color)
        css_content += f"  --{variable_prefix}-{i}: {hex_color};\n"
    
    css_content += "}\n\n"
    
    # Add utility classes for each color
    css_content += "/* Color utility classes */\n"
    for i, color in enumerate(colors, start=1):
        hex_color = rgb_to_hex(color)
        css_content += f".{variable_prefix}-{i} {{\n"
        css_content += f"  color: {hex_color};\n"
        css_content += "}\n\n"
        css_content += f".{variable_prefix}-{i}-bg {{\n"
        css_content += f"  background-color: {hex_color};\n"
        css_content += "}\n\n"
    
    try:
        with open(output_path, 'w') as f:
            f.write(css_content)
        print(f"Colors exported to {output_path}")
    except Exception as e:
        print(f"Error writing CSS file: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description='Extract colors from an image and export to CSS',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Extract 5 most common distinct colors
  %(prog)s image.jpg -n 5 -o colors.css
  
  # Extract most common color with 7 variations
  %(prog)s image.jpg --variations 7 -o colors.css
  
  # Extract colors within range of most common color
  %(prog)s image.jpg --range 60 -o colors.css
  
  # Extract colors within range with custom palette size
  %(prog)s image.jpg --range 40 --range-palette-size 8 -o colors.css
  
  # Extract 10 colors with custom variable prefix
  %(prog)s image.jpg -n 10 --prefix theme -o theme-colors.css
        """
    )
    
    parser.add_argument('image', type=str, help='Path to the input image')
    parser.add_argument('-o', '--output', type=str, default='colors.css',
                       help='Output CSS file path (default: colors.css)')
    parser.add_argument('-n', '--num-colors', type=int, default=None,
                       help='Number of distinct colors to extract (uses clustering to avoid similar colors)')
    parser.add_argument('--variations', type=int, default=None,
                       help='Extract most common color with this many variations (lighter/darker shades)')
    parser.add_argument('--range', type=float, default=None, metavar='THRESHOLD',
                       help='Extract colors within this distance range of the most common color (0-255*√3 scale, default: 50)')
    parser.add_argument('--range-palette-size', type=int, default=10, metavar='SIZE',
                       help='Maximum number of colors in range-based palette (default: 10)')
    parser.add_argument('--prefix', type=str, default='color',
                       help='Prefix for CSS variable names (default: color)')
    
    args = parser.parse_args()
    
    # Validate that image exists
    image_path = Path(args.image)
    if not image_path.exists():
        print(f"Error: Image file '{args.image}' not found", file=sys.stderr)
        sys.exit(1)
    
    # Determine which mode to use (priority: range > variations > num-colors > default)
    if args.range is not None:
        if args.num_colors is not None or args.variations is not None:
            print("Warning: --range takes priority over other color extraction options.", file=sys.stderr)
        range_threshold = max(1.0, args.range)
        palette_size = max(1, args.range_palette_size)
        colors = extract_color_range_palette(str(image_path), range_threshold, palette_size)
        print(f"Extracted {len(colors)} colors within range {range_threshold} of most common color")
    elif args.variations is not None:
        if args.num_colors is not None:
            print("Warning: Both --num-colors and --variations specified. Using --variations.", file=sys.stderr)
        num_variations = max(1, args.variations)
        colors = extract_color_with_variations(str(image_path), num_variations)
        print(f"Extracted most common color with {len(colors)} variations")
    elif args.num_colors is not None:
        n = max(1, args.num_colors)
        colors = extract_n_common_colors(str(image_path), n, use_clustering=True)
        print(f"Extracted {len(colors)} distinct colors")
    else:
        # Default: extract 5 colors
        colors = extract_n_common_colors(str(image_path), 5, use_clustering=True)
        print(f"Extracted {len(colors)} distinct colors (default)")
    
    # Export to CSS
    export_to_css(colors, args.output, args.prefix)
    
    # Print colors for preview
    print("\nExtracted colors:")
    for i, color in enumerate(colors, start=1):
        hex_color = rgb_to_hex(color)
        print(f"  {i}. {hex_color} (RGB{color})")


if __name__ == '__main__':
    main()


