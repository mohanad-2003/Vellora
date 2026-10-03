import { isPackshot } from './packshots.js';

const iso = (d) => (d instanceof Date ? d.toISOString() : d);

/** Absolute URL for an image path stored relative to public/images. */
export function imageUrl(req, path) {
  const url = `${req.protocol}://${req.get('host')}/static/images/${path}`;
  return isPackshot(path) ? `${url}?packshot=1` : url;
}

export function userDto(u) {
  return { id: u.id, name: u.name, email: u.email, createdAt: iso(u.created_at) };
}

/** Product card shape used by lists (home, catalog, wishlist, related). */
export function productDto(req, row, favorites) {
  return {
    id: row.id,
    name: row.name,
    brand: row.brand,
    category: row.category_id,
    imageUrl: imageUrl(req, row.image),
    isPackshot: isPackshot(row.image),
    price: row.price,
    originalPrice: row.original_price,
    rating: row.rating,
    reviewCount: row.review_count,
    inStock: row.in_stock,
    isFavorite: favorites ? favorites.has(row.id) : false,
  };
}

export function reviewDto(r) {
  return {
    id: r.id,
    author: r.author,
    rating: r.rating,
    comment: r.comment,
    createdAt: iso(r.created_at),
  };
}

export function notificationDto(n) {
  return {
    id: n.id,
    kind: n.kind,
    title: n.title,
    body: n.body,
    isUnread: n.is_unread,
    createdAt: iso(n.created_at),
  };
}

export function orderDto(req, o, items) {
  return {
    id: o.id,
    number: o.number,
    status: o.status,
    createdAt: iso(o.created_at),
    items: items.map((i) => ({
      productId: i.product_id,
      name: i.name,
      imageUrl: imageUrl(req, i.image),
      quantity: i.quantity,
      price: i.price,
      color: i.color,
      size: i.size,
    })),
    subtotal: o.subtotal,
    discount: o.discount,
    shipping: o.shipping,
    total: o.total,
    promoCode: o.promo_code,
    delivery: o.delivery,
    address: {
      recipient: o.recipient,
      phone: o.phone,
      line: o.address_line,
      city: o.city,
    },
    payment: { kind: o.payment_kind, detail: o.payment_detail },
  };
}
